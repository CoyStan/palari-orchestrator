const state = {
  snapshot: null,
  queueFilter: "attention",
  query: "",
  selectedTicketId: "",
};

const $ = (selector) => document.querySelector(selector);

const statusLabels = {
  accepted: "Accepted",
  claimed: "Claimed",
  open: "Open",
  "needs-human": "Needs human",
  "in-review": "In review",
  reopened: "Reopened",
};

const severityLabels = {
  blocked: "Blocked",
  waiting: "Waiting",
  watch: "Watch",
  next: "Next",
  clear: "Clear",
};

function setStatusMessage(message) {
  $("#dashboardStatus").textContent = message;
}

function label(value) {
  return statusLabels[value] || String(value || "unknown").replace(/^\w/, (match) => match.toUpperCase());
}

function formatTimestamp(value) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return `Updated ${value}`;
  return `Updated ${date.toISOString().slice(11, 19)}Z`;
}

function compactLabel(value, limit = 28) {
  const text = String(value || "");
  if (text.length <= limit) return text;
  const head = Math.max(8, Math.floor((limit - 3) * 0.58));
  const tail = Math.max(6, limit - 3 - head);
  return `${text.slice(0, head)}...${text.slice(-tail)}`;
}

function emptyNode(message = "No records yet", detail = "The console will populate as the repository changes.") {
  const template = $("#emptyTemplate").content.cloneNode(true);
  template.querySelector("strong").textContent = message;
  template.querySelector("span").textContent = detail;
  return template;
}

function statusPill(status, text = label(status)) {
  const span = document.createElement("span");
  span.className = `status ${status || "open"}`;
  span.textContent = text;
  span.setAttribute("aria-label", `Status: ${text}`);
  return span;
}

function severityPill(severity) {
  return statusPill(severity, severityLabels[severity] || label(severity));
}

function meta(items) {
  const row = document.createElement("div");
  row.className = "meta";
  items.filter(Boolean).forEach((item) => {
    const span = document.createElement("span");
    span.textContent = item;
    row.append(span);
  });
  return row;
}

function pathList(paths, limit = 3) {
  const row = document.createElement("div");
  row.className = "path-list";
  paths.slice(0, limit).forEach((path) => {
    const span = document.createElement("span");
    span.textContent = path;
    row.append(span);
  });
  if (paths.length > limit) {
    const span = document.createElement("span");
    span.textContent = `+${paths.length - limit} more`;
    row.append(span);
  }
  return row;
}

function activeTickets(snapshot) {
  return snapshot.tickets.filter((ticket) => ticket.status !== "accepted");
}

function actionSeverity(ticket) {
  return ticket.next_action?.severity || "watch";
}

function ticketQueue(ticket) {
  if (ticket.status === "accepted") return "done";
  if (ticket.status === "in-review") return "review";
  if (["blocked", "needs-human"].includes(ticket.status)) return "attention";
  if (["blocked", "waiting", "watch"].includes(actionSeverity(ticket))) return "attention";
  return "active";
}

function ticketOwner(ticket) {
  return ticket.claimed_by || ticket.accepted_by || "Unassigned";
}

function ticketRole(ticket) {
  return ticket.delegated_to_role || ticket.created_by_role || "No role";
}

function ticketSearchText(ticket) {
  return [
    ticket.id,
    ticket.title,
    ticket.status,
    ticket.risk,
    ticket.priority,
    ticket.stream,
    ticketOwner(ticket),
    ticketRole(ticket),
    ticket.next_action?.label,
    ticket.next_action?.detail,
    ticket.path,
    ticket.branch,
    ticket.worktree,
    ...(ticket.allowed_paths || []),
    ...(ticket.forbidden_paths || []),
    ...(ticket.required_reports || []),
    ...(ticket.evidence?.files || []),
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();
}

function matchesSearch(ticket) {
  const query = state.query.trim().toLowerCase();
  if (!query) return true;
  return query.split(/\s+/).every((term) => ticketSearchText(ticket).includes(term));
}

function searchedTickets(snapshot) {
  return (snapshot.tickets || []).filter(matchesSearch);
}

function defaultSelectedTicket(tickets) {
  return tickets.find((ticket) => ticketQueue(ticket) === "attention")
    || tickets.find((ticket) => ticketQueue(ticket) === "review")
    || tickets.find((ticket) => ticketQueue(ticket) === "active")
    || tickets[0]
    || null;
}

function ensureSelectedTicket(snapshot) {
  const tickets = snapshot.tickets || [];
  const visible = searchedTickets(snapshot);
  const pool = visible.length ? visible : tickets;
  const selectedIsVisible = pool.some((ticket) => ticket.id === state.selectedTicketId);
  if (!selectedIsVisible) {
    const ticket = defaultSelectedTicket(pool);
    state.selectedTicketId = ticket?.id || "";
  }
}

function selectTicket(id) {
  state.selectedTicketId = id;
  if (!state.snapshot) return;
  renderQueue(state.snapshot);
  renderTicketRows(state.snapshot);
  renderTicketFocus(state.snapshot);
  setStatusMessage(`Selected ticket ${id}`);
}

function renderMetrics(snapshot) {
  const tickets = snapshot.tickets || [];
  const attention = tickets.filter((ticket) => ticketQueue(ticket) === "attention").length;
  $("#countAttention").textContent = attention;
  $("#countActive").textContent = activeTickets(snapshot).length;
  $("#countReview").textContent = snapshot.counts["in-review"] || 0;
  $("#countAccepted").textContent = snapshot.counts.accepted || 0;
}

function healthIssues(snapshot) {
  const issues = [];
  const firstActive = activeTickets(snapshot)[0];
  const ticket = firstActive?.id || "TICKET-ID";

  if (!snapshot.workflow.workflow_installed) {
    issues.push({
      label: "Workflow missing",
      detail: "Install the Palari CI workflow so repository gates can run.",
      command: "./bin/palari init --ci",
      severity: "blocked",
    });
  }
  if (!snapshot.workflow.ruleset_template) {
    issues.push({
      label: "Ruleset template missing",
      detail: "Create the GitHub ruleset template before expecting required checks.",
      command: "./bin/palari init --ci",
      severity: "blocked",
    });
  }
  if (!snapshot.workflow.attestation) {
    issues.push({
      label: "Evidence attestation missing",
      detail: "Review the Palari workflow before treating evidence as verifiable.",
      command: "sed -n '1,220p' .github/workflows/palari.yml",
      severity: "watch",
    });
  }
  if (snapshot.roles && snapshot.roles.lint && !snapshot.roles.lint.ok) {
    issues.push({
      label: `${snapshot.roles.lint.issues} role issue${snapshot.roles.lint.issues === 1 ? "" : "s"}`,
      detail: "Role authority should be lint-clean before delegation is trusted.",
      command: snapshot.roles.lint.command || "./bin/palari role lint",
      severity: "blocked",
    });
  }
  if (snapshot.health.overlaps) {
    issues.push({
      label: `${snapshot.health.overlaps} scope overlap${snapshot.health.overlaps > 1 ? "s" : ""}`,
      detail: "Resolve overlapping active write scopes before continuing parallel work.",
      command: "./bin/palari scope-overlaps",
      severity: "blocked",
    });
  }
  if (snapshot.health.stale_claims) {
    issues.push({
      label: `${snapshot.health.stale_claims} stale claim${snapshot.health.stale_claims > 1 ? "s" : ""}`,
      detail: "Refresh or release stale leases so ownership is clear.",
      command: `./bin/palari ticket heartbeat ${ticket}`,
      severity: "watch",
    });
  }
  if (snapshot.health.missing_evidence) {
    issues.push({
      label: `${snapshot.health.missing_evidence} ticket${snapshot.health.missing_evidence > 1 ? "s" : ""} missing evidence`,
      detail: "Run CI evidence before review or acceptance.",
      command: `./bin/palari ci ${ticket} --base ${snapshot.config.default_branch}`,
      severity: "blocked",
    });
  }
  if (snapshot.health.dirty_paths) {
    issues.push({
      label: `${snapshot.health.dirty_paths} changed path${snapshot.health.dirty_paths > 1 ? "s" : ""}`,
      detail: "Inspect local changes before acceptance or handoff.",
      command: "git status --short",
      severity: "watch",
    });
  }

  return issues;
}

function makeCopyButton(command, labelText = "Copy command") {
  const button = document.createElement("button");
  button.className = "copy";
  button.type = "button";
  button.textContent = "Copy";
  button.disabled = !command;
  button.setAttribute("aria-label", `${labelText}: ${command || "no command"}`);
  button.addEventListener("click", async (event) => {
    event.stopPropagation();
    if (!command) return;
    try {
      await navigator.clipboard.writeText(command);
      button.textContent = "Copied";
      setStatusMessage(`Copied command: ${command}`);
      setTimeout(() => {
        button.textContent = "Copy";
      }, 1100);
    } catch (error) {
      button.textContent = "Failed";
      setStatusMessage(`Copy failed: ${error.message}`);
      setTimeout(() => {
        button.textContent = "Copy";
      }, 1400);
    }
  });
  return button;
}

function health(snapshot) {
  const issues = healthIssues(snapshot);

  const grade = issues.some((issue) => issue.severity === "blocked")
    ? "Blocked"
    : issues.length
      ? "Watch"
      : "Clear";
  document.body.dataset.health = grade.toLowerCase();
  $("#healthGrade").textContent = grade;
  $("#healthSummary").textContent = issues.length ? issues.map((issue) => issue.label).join(" · ") : "Workflow, evidence, roles, claims, and scope look clean.";
  $("#railState").textContent = grade;
  $("#railDetail").textContent = issues.length ? issues[0].label : "Governance model is clean";
  $("#warningPill").textContent = `${issues.length} warning${issues.length === 1 ? "" : "s"}`;
}

function renderHealthActions(snapshot) {
  const list = $("#healthActionsList");
  list.replaceChildren();
  const issues = healthIssues(snapshot);

  if (!issues.length) {
    const node = document.createElement("article");
    node.className = "health-action clear";
    const strong = document.createElement("strong");
    strong.textContent = "No system warning";
    const detail = document.createElement("span");
    detail.textContent = "Workflow, evidence, role authority, claims, and scope are clean.";
    node.append(strong, detail);
    list.append(node);
    return;
  }

  issues.forEach((issue) => {
    const node = document.createElement("article");
    node.className = `health-action ${issue.severity}`;
    const copy = makeCopyButton(issue.command, issue.label);
    const copyRow = document.createElement("div");
    copyRow.className = "health-action-command";
    const code = document.createElement("code");
    code.textContent = issue.command;
    copyRow.append(code, copy);

    const strong = document.createElement("strong");
    strong.textContent = issue.label;
    const detail = document.createElement("span");
    detail.textContent = issue.detail;
    node.append(strong, detail, copyRow);
    list.append(node);
  });
}

function renderOperatorSummary(snapshot) {
  const action = snapshot.operator?.next_action || {};
  const waitingHuman = activeTickets(snapshot).filter((ticket) => ticket.next_action?.actor === "human" || ticket.status === "needs-human");
  const roleCount = snapshot.roles?.counts?.active || 0;
  const roleLintOk = snapshot.roles?.lint?.ok !== false;

  $("#operatorNext").textContent = action.label || "Inspect repository";
  $("#operatorDetail").textContent = action.detail || "Open the queue for the next ticket action.";
  $("#humanGate").textContent = waitingHuman.length ? `${waitingHuman.length} waiting` : "Clear";
  $("#humanGateDetail").textContent = waitingHuman.length
    ? waitingHuman.map((ticket) => ticket.id).join(", ")
    : "No active ticket is waiting on a human decision.";
  $("#roleSystem").textContent = roleLintOk ? `${roleCount} active` : "Needs review";
  $("#roleSystemDetail").textContent = roleLintOk
    ? "Role authority is lint-clean."
    : "Run role lint before trusting delegation.";
}

function queueItems(snapshot) {
  const tickets = searchedTickets(snapshot);
  if (state.queueFilter === "all") return tickets;
  return tickets.filter((ticket) => ticketQueue(ticket) === state.queueFilter);
}

function renderQueue(snapshot) {
  const list = $("#queueList");
  list.replaceChildren();
  const tickets = queueItems(snapshot);
  const searched = searchedTickets(snapshot);
  const total = snapshot.tickets?.length || 0;
  const searchText = state.query.trim() ? `${searched.length} of ${total} matching` : `${total} total`;
  $("#queueResultLine").textContent = `${tickets.length} shown · ${searchText}`;

    if (!tickets.length) {
    const action = snapshot.operator?.next_action;
    if (!state.query.trim() && state.queueFilter === "attention" && action && !snapshot.operator.has_active_work) {
      const node = document.createElement("article");
      node.className = "queue-item clear";
      const top = document.createElement("div");
      top.className = "queue-top";
      const title = document.createElement("strong");
      title.textContent = action.label;
      top.append(title, severityPill(action.severity || "clear"));
      const detail = document.createElement("p");
      detail.textContent = action.detail;
      node.append(top, detail);
      if (action.command) node.append(commandInline(action.command, action.label));
      list.append(node);
      return;
    }
    const detail = state.query.trim()
      ? "Search terms matched tickets, but the current filter hides them. Try switching to All tickets or clearing the search."
      : "No tickets match this queue filter. Change the filter or create a scoped ticket.";
    list.append(emptyNode("No matching tickets", detail));
    return;
  }

  tickets.forEach((ticket) => {
    const action = ticket.next_action || {};
    const node = document.createElement("article");
    node.className = `queue-item ${action.severity || ticket.status}`;
    if (ticket.id === state.selectedTicketId) {
      node.classList.add("selected");
    }
    const top = document.createElement("div");
    top.className = "queue-top";
    const title = document.createElement("div");
    const strong = document.createElement("strong");
    strong.textContent = `${ticket.id} · ${ticket.title}`;
    title.append(strong, meta([ticket.stream, ticket.risk, ticket.priority, ticketOwner(ticket), ticketRole(ticket)]));
    const actions = document.createElement("div");
    actions.className = "queue-actions";
    const focus = document.createElement("button");
    focus.type = "button";
    focus.className = "copy focus-ticket";
    focus.textContent = ticket.id === state.selectedTicketId ? "Viewing" : "View";
    focus.setAttribute("aria-label", `Show ${ticket.id} in review focus`);
    focus.setAttribute("aria-pressed", ticket.id === state.selectedTicketId ? "true" : "false");
    focus.addEventListener("click", () => selectTicket(ticket.id));
    actions.append(severityPill(action.severity || ticket.status), focus);
    top.append(title, actions);

    const detail = document.createElement("p");
    detail.textContent = action.detail || "Inspect this ticket before continuing.";
    node.append(top, detail, progressRail(ticket));
    if (action.command) node.append(commandInline(action.command, action.label || ticket.id));
    list.append(node);
  });
}

function progressRail(ticket) {
  const row = document.createElement("div");
  row.className = "progress-rail";
  const steps = [
    ["Ticket", true],
    ["Claim", Boolean(ticket.claimed_by || ticket.status === "accepted")],
    ["Evidence", ticket.evidence.file_count > 0],
    ["Review", Boolean(ticket.reports.reviewer || ticket.status === "accepted")],
    ["Accept", ticket.status === "accepted"],
  ];
  steps.forEach(([name, done]) => {
    const span = document.createElement("span");
    span.className = done ? "done" : "";
    span.textContent = name;
    row.append(span);
  });
  return row;
}

function commandInline(command, labelText) {
  const action = document.createElement("div");
  action.className = "inline-command";
  const code = document.createElement("code");
  code.textContent = command;
  action.append(code, makeCopyButton(command, labelText));
  return action;
}

function evidenceState(ticket) {
  const evidence = ticket.evidence;
  const complete = evidence.has_log && evidence.has_junit && evidence.has_sarif && ticket.evidence.has_manifest;
  if (complete) return "Complete";
  if (evidence.file_count > 0) return "Partial";
  return "Missing";
}

function evidenceDetail(ticket) {
  const evidence = ticket.evidence;
  if (evidence.file_count === 0) return "No evidence files attached.";
  const missing = [];
  if (!evidence.has_log) missing.push("log");
  if (!evidence.has_junit) missing.push("JUnit");
  if (!evidence.has_sarif) missing.push("SARIF");
  if (!evidence.has_manifest) missing.push("manifest");
  if (!missing.length) return `${evidence.file_count} artifact${evidence.file_count === 1 ? "" : "s"}, all present.`;
  return `Missing: ${missing.join(", ")}.`;
}

function renderTicketRows(snapshot) {
  const body = $("#ticketRows");
  body.replaceChildren();
  const tickets = searchedTickets(snapshot);
  const total = snapshot.tickets?.length || 0;
  $("#ticketPill").textContent = state.query.trim()
    ? `${tickets.length} of ${total}`
    : `${tickets.length} ticket${tickets.length === 1 ? "" : "s"}`;

  if (!tickets.length) {
    const row = document.createElement("tr");
    const cell = document.createElement("td");
    cell.colSpan = 6;
    const hasTickets = snapshot.tickets?.length > 0;
    const isFiltered = state.query.trim() && hasTickets;
    cell.append(emptyNode(isFiltered ? "No tickets match search" : "No tickets yet", isFiltered ? "Adjust or clear search terms to see all tickets." : "Create or adopt a scoped ticket to begin."));
    row.append(cell);
    body.append(row);
    return;
  }

  tickets.forEach((ticket) => {
    const row = document.createElement("tr");
    if (ticket.id === state.selectedTicketId) row.className = "selected";
    const ticketCell = document.createElement("td");
    ticketCell.dataset.label = "Ticket";
    const link = document.createElement("button");
    link.type = "button";
    link.className = "ticket-link";
    link.addEventListener("click", () => selectTicket(ticket.id));
    const title = document.createElement("strong");
    title.textContent = ticket.id;
    const subtitle = document.createElement("span");
    subtitle.textContent = ticket.title;
    link.append(title, subtitle);
    ticketCell.append(link, meta([ticket.stream, ticket.risk, ticket.status]));

    const owner = document.createElement("td");
    owner.dataset.label = "Owner";
    owner.textContent = ticketOwner(ticket);

    const role = document.createElement("td");
    role.dataset.label = "Role";
    role.textContent = ticketRole(ticket);

    const progress = document.createElement("td");
    progress.dataset.label = "Progress";
    progress.append(progressRail(ticket));

    const evidence = document.createElement("td");
    evidence.dataset.label = "Evidence";
    evidence.append(statusPill(evidenceState(ticket).toLowerCase(), evidenceState(ticket)));

    const next = document.createElement("td");
    next.dataset.label = "Next";
    const nextStrong = document.createElement("strong");
    nextStrong.textContent = ticket.next_action?.label || "Inspect";
    next.append(nextStrong);
    row.append(ticketCell, owner, role, progress, evidence, next);
    body.append(row);
  });
}

function renderRoles(snapshot) {
  const list = $("#roleList");
  list.replaceChildren();
  const roles = snapshot.roles?.items || [];
  const active = roles.filter((role) => role.status === "active");
  $("#rolesPill").textContent = `${active.length} active`;

  if (!roles.length) {
    list.append(emptyNode("No roles configured", "Use role proposals when delegation needs a named authority boundary."));
    return;
  }

  roles.forEach((role) => {
    const node = document.createElement("article");
    node.className = "role-row";
    const top = document.createElement("div");
    top.className = "role-top";
    const title = document.createElement("div");
    const strong = document.createElement("strong");
    strong.textContent = role.title || role.id;
    title.append(strong, meta([role.id, `tier ${role.tier || "?"}`, `max ${role.max_risk || "?"}`, role.parent_role && `parent ${role.parent_role}`]));
    top.append(title, statusPill(role.status || "unknown"));
    const caps = document.createElement("div");
    caps.className = "capability-row";
    [
      ["Create", role.capabilities?.may_create_tickets],
      ["Execute", role.capabilities?.may_execute_tickets],
      ["Review", role.capabilities?.may_review_tickets],
      ["Accept", role.capabilities?.may_accept_tickets],
    ].forEach(([name, enabled]) => {
      const span = document.createElement("span");
      span.className = enabled ? "enabled" : "";
      span.textContent = name;
      caps.append(span);
    });
    node.append(top, caps);
    if (role.can_delegate_to?.length) node.append(pathList(role.can_delegate_to, 4));
    list.append(node);
  });
}

function renderEvidence(snapshot) {
  const list = $("#evidenceList");
  list.replaceChildren();
  const tickets = snapshot.tickets.filter((ticket) => ticket.status !== "accepted" || ticket.evidence.file_count > 0);
  const bundles = snapshot.tickets.filter((ticket) => ticket.evidence.file_count > 0);
  const missing = tickets.filter((ticket) => ticket.evidence.file_count === 0);
  $("#evidencePill").textContent = missing.length
    ? `${bundles.length} present · ${missing.length} missing`
    : `${bundles.length} bundle${bundles.length === 1 ? "" : "s"}`;

  if (!tickets.length) {
    list.append(emptyNode("No evidence bundles", "Run palari ci TICKET-ID to create logs, JUnit, SARIF, and manifest."));
    return;
  }

  tickets.forEach((ticket) => {
    const node = document.createElement("article");
    node.className = "evidence";

    const top = document.createElement("div");
    top.className = "evidence-top";
    const title = document.createElement("div");
    const strong = document.createElement("strong");
    strong.textContent = ticket.id;
    const evidenceText = ticket.evidence.file_count > 0 ? `${ticket.evidence.file_count} files` : "missing evidence";
    title.append(strong, meta([ticket.evidence.path || "reports/evidence", evidenceText]));
    top.append(title, statusPill(evidenceState(ticket).toLowerCase(), evidenceState(ticket)));

    const grid = document.createElement("div");
    grid.className = "evidence-grid";
    [
      ["Log", ticket.evidence.has_log],
      ["JUnit", ticket.evidence.has_junit],
      ["SARIF", ticket.evidence.has_sarif],
      ["Manifest", ticket.evidence.has_manifest],
    ].forEach(([name, yes]) => {
      const span = document.createElement("span");
      span.className = yes ? "yes" : "";
      span.textContent = `${name}: ${yes ? "present" : "missing"}`;
      grid.append(span);
    });

    node.append(top, grid);
    if (ticket.evidence.file_count === 0) {
      const command = `./bin/palari ci ${ticket.id} --base ${snapshot.config.default_branch}`;
      node.append(commandInline(command, `Create evidence for ${ticket.id}`));
    }
    list.append(node);
  });
}

function renderScope(snapshot) {
  const list = $("#scopeMap");
  list.replaceChildren();
  $("#scopePill").textContent = snapshot.overlaps.length ? `${snapshot.overlaps.length} blocked` : "clean";

  if (!snapshot.overlaps.length) {
    const clean = document.createElement("article");
    clean.className = "scope-row";
    const left = document.createElement("span");
    left.textContent = "No overlapping active write scopes";
    const connector = document.createElement("i");
    connector.className = "connector";
    connector.setAttribute("aria-hidden", "true");
    const right = document.createElement("span");
    right.textContent = "Path partitioning is clean";
    clean.append(left, connector, right);
    list.append(clean);
    return;
  }

  snapshot.overlaps.forEach((finding) => {
    const row = document.createElement("article");
    row.className = "scope-row";
    const left = document.createElement("span");
    left.textContent = `${finding.left}: ${finding.left_pattern}`;
    const connector = document.createElement("i");
    connector.className = "connector";
    connector.setAttribute("aria-hidden", "true");
    const right = document.createElement("span");
    right.textContent = `${finding.right}: ${finding.right_pattern}`;
    row.append(left, connector, right);
    list.append(row);
  });
}

function commandRows(snapshot) {
  const firstActive = activeTickets(snapshot)[0];
  const ticket = firstActive?.id || "TICKET-ID";
  const rows = [
    ["Status", "./bin/palari status --next"],
    ["Role lint", "./bin/palari role lint"],
    ["Lifecycle audit", "./bin/palari ticket audit"],
    ["Ruleset activation", "./bin/palari github ruleset-command --repo OWNER/REPO"],
  ];
  if (firstActive?.next_action?.command) {
    rows.unshift([firstActive.next_action.label, firstActive.next_action.command]);
  } else if (snapshot.operator?.next_action?.command) {
    rows.unshift([snapshot.operator.next_action.label, snapshot.operator.next_action.command]);
  }
  rows.push(["Scope", `./bin/palari scope-check ${ticket}`]);
  rows.push(["CI evidence", `./bin/palari ci ${ticket} --base ${snapshot.config.default_branch}`]);
  return rows;
}

function renderCommands(snapshot) {
  const list = $("#commandList");
  list.replaceChildren();
  commandRows(snapshot).forEach(([name, command]) => {
    const node = document.createElement("article");
    node.className = "command";
    const top = document.createElement("div");
    top.className = "command-top";
    const strong = document.createElement("strong");
    strong.textContent = name;
    const button = makeCopyButton(command, name);
    const code = document.createElement("code");
    code.textContent = command;
    top.append(strong, button);
    node.append(top, code);
    list.append(node);
  });
}

function renderHumanSummary(snapshot) {
  const node = $("#humanSummary");
  node.replaceChildren();
  const waiting = activeTickets(snapshot).filter((ticket) => ticket.next_action?.actor === "human" || ticket.status === "needs-human");
  $("#humanPill").textContent = waiting.length ? `${waiting.length} waiting` : "clear";

  if (!waiting.length) {
    node.append(emptyNode("No human decision queued", "When a ticket needs acceptance, product direction, or authority, it will appear here."));
    return;
  }

  waiting.forEach((ticket) => {
    const item = document.createElement("article");
    item.className = "human-item";
    const strong = document.createElement("strong");
    strong.textContent = `${ticket.id}: ${ticket.next_action?.label || "Human decision"}`;
    const detail = document.createElement("p");
    detail.textContent = ticket.next_action?.detail || "Inspect this ticket before continuing.";
    item.append(strong, detail);
    if (ticket.next_action?.command) item.append(commandInline(ticket.next_action.command, ticket.id));
    node.append(item);
  });
}

function reportItems(ticket) {
  const custom = ticket.reports?.custom || [];
  const required = new Set(ticket.required_reports || []);
  const reports = [["Specialist", ticket.reports?.technical]];
  if (ticket.requires_review !== false || required.has("reviewer")) {
    reports.push(["Reviewer", ticket.reports?.reviewer]);
  }
  if (ticket.requires_human_confirmation || required.has("human") || ticket.status === "needs-human") {
    reports.push(["Human", ticket.reports?.human]);
  }
  custom.forEach((report) => {
    reports.push([label(report.name), report.present]);
  });
  return reports;
}

function reportSummary(ticket) {
  const reports = reportItems(ticket);
  const present = reports.filter(([, yes]) => yes).length;
  return `${present} of ${reports.length} reports`;
}

function readinessCard(labelText, value, detail, stateName) {
  const card = document.createElement("article");
  card.className = `readiness ${stateName}`;
  const span = document.createElement("span");
  span.textContent = labelText;
  const strong = document.createElement("strong");
  strong.textContent = value;
  const small = document.createElement("small");
  small.textContent = detail;
  card.append(span, strong, small);
  return card;
}

function timelineStep(name, done, detail) {
  const item = document.createElement("li");
  item.className = done ? "done" : "pending";
  const marker = document.createElement("i");
  marker.setAttribute("aria-hidden", "true");
  const body = document.createElement("div");
  const strong = document.createElement("strong");
  strong.textContent = name;
  const span = document.createElement("span");
  span.textContent = detail;
  body.append(strong, span);
  item.append(marker, body);
  return item;
}

function renderTicketFocus(snapshot) {
  const host = $("#ticketFocus");
  host.replaceChildren();
  ensureSelectedTicket(snapshot);
  const ticket = (snapshot.tickets || []).find((item) => item.id === state.selectedTicketId);

  if (!ticket) {
    $("#focusPill").textContent = "none";
    host.append(emptyNode("No ticket selected", "Select a ticket from the queue or table to inspect its readiness, evidence, evidence artifacts, and acceptance eligibility."));
    return;
  }

  const action = ticket.next_action || {};
  const evidence = evidenceState(ticket);
  const humanGate = ticket.requires_human_confirmation || action.actor === "human" || ticket.status === "needs-human";
  const acceptReady = action.actor === "human" && /accept/i.test(action.label || "");
  $("#focusPill").textContent = label(ticket.status);

  const header = document.createElement("article");
  header.className = "focus-hero";
  const title = document.createElement("div");
  const strong = document.createElement("strong");
  strong.textContent = ticket.id;
  const heading = document.createElement("h3");
  heading.textContent = ticket.title;
  title.append(strong, heading, meta([ticket.stream, ticket.risk, ticket.priority, ticketOwner(ticket), ticketRole(ticket)]));
  header.append(title, statusPill(ticket.status));

  const next = document.createElement("article");
  next.className = "focus-next";
  const nextLabel = document.createElement("span");
  nextLabel.textContent = "Next action";
  const nextTitle = document.createElement("strong");
  nextTitle.textContent = action.label || "Inspect ticket";
  const nextDetail = document.createElement("p");
  nextDetail.textContent = action.detail || "Review the ticket state before continuing.";
  next.append(nextLabel, nextTitle, nextDetail);
  if (action.command) next.append(commandInline(action.command, action.label || ticket.id));

  const readiness = document.createElement("div");
  readiness.className = "readiness-grid";
  const missingReports = reportItems(ticket).filter(([, yes]) => !yes).map(([name]) => name);
  readiness.append(
    readinessCard("Evidence", evidence, evidenceDetail(ticket), evidence.toLowerCase()),
    readinessCard("Review", reportSummary(ticket), missingReports.length ? `Needs: ${missingReports.join(", ")}.` : "All required review notes are present.", reportItems(ticket).every(([, yes]) => yes) ? "complete" : "partial"),
    readinessCard("Human gate", humanGate ? "Waiting" : "Clear", acceptReady ? "Acceptance is ready for an authorized person." : humanGate ? "Waiting on human decision." : "No human gate is blocking this ticket.", humanGate ? "waiting" : "complete"),
    readinessCard("Lease", ticket.lease?.status ? label(ticket.lease.status) : "No lease", ticket.claim_heartbeat_at ? `Heartbeat ${ticket.claim_heartbeat_at}` : "No active lease on this ticket.", !ticket.lease?.status || ticket.lease?.status === "expired" ? "missing" : "complete"),
  );

  const timeline = document.createElement("ol");
  timeline.className = "timeline";
  timeline.append(
    timelineStep("Ticket", true, ticket.path || "Ticket file exists."),
    timelineStep("Claim", Boolean(ticket.claimed_by || ticket.status === "accepted"), ticket.claimed_by ? `${ticket.claimed_by} owns the work.` : "No owner has claimed this ticket."),
    timelineStep("Evidence", ticket.evidence.file_count > 0, `${evidence} evidence bundle.`),
    timelineStep("Review", Boolean(ticket.reports?.reviewer || ticket.status === "accepted"), ticket.reports?.reviewer ? "Reviewer note is present." : "Fresh reviewer note is still needed."),
    timelineStep("Human gate", humanGate || ticket.status === "accepted", humanGate ? action.label || "Human decision required." : "No human gate is blocking this ticket."),
    timelineStep("Accepted", ticket.status === "accepted", ticket.accepted_by ? `Accepted by ${ticket.accepted_by}.` : "Not accepted yet."),
  );

  const scope = document.createElement("article");
  scope.className = "focus-section";
  const scopeTitle = document.createElement("strong");
  scopeTitle.textContent = "Scope";
  scope.append(scopeTitle);
  if (ticket.allowed_paths?.length) scope.append(pathList(ticket.allowed_paths, 5));
  if (ticket.forbidden_paths?.length) {
    const forbidden = document.createElement("div");
    forbidden.className = "forbidden-note";
    forbidden.textContent = `Forbidden: ${ticket.forbidden_paths.slice(0, 4).join(", ")}${ticket.forbidden_paths.length > 4 ? "..." : ""}`;
    scope.append(forbidden);
  }

  const artifacts = document.createElement("article");
  artifacts.className = "focus-section";
  const artifactTitle = document.createElement("strong");
  artifactTitle.textContent = "Artifacts";
  artifacts.append(artifactTitle);
  const artifactMeta = meta([
    ticket.evidence.path || "No evidence path",
    ticket.evidence.has_log && "log",
    ticket.evidence.has_junit && "JUnit",
    ticket.evidence.has_sarif && "SARIF",
    ticket.evidence.has_manifest && "manifest",
  ]);
  artifacts.append(artifactMeta);
  if (ticket.evidence.files?.length) artifacts.append(pathList(ticket.evidence.files, 6));

  host.append(header, next, readiness, timeline, scope, artifacts);
}

function renderStatus(snapshot) {
  const branch = snapshot.git.branch || "detached";
  $("#branchPill").textContent = compactLabel(branch);
  $("#branchPill").title = branch;
  const palari = snapshot.palari_status.stdout || snapshot.palari_status.stderr || "No palari status output.";
  const git = snapshot.git.status || "No git status output.";
  $("#statusOutput").textContent = `${palari}\n\n${git}`;
}

function render(snapshot) {
  state.snapshot = snapshot;
  $("#projectName").textContent = snapshot.project;
  $("#railProject").textContent = snapshot.project;
  $("#timestamp").textContent = formatTimestamp(snapshot.generated_at);
  $("#timestamp").title = `Updated ${snapshot.generated_at}`;
  $("#authorityChip").textContent = `authority: ${snapshot.authority.profile}`;
  ensureSelectedTicket(snapshot);
  renderMetrics(snapshot);
  health(snapshot);
  renderHealthActions(snapshot);
  renderOperatorSummary(snapshot);
  renderQueue(snapshot);
  renderTicketRows(snapshot);
  renderTicketFocus(snapshot);
  renderRoles(snapshot);
  renderEvidence(snapshot);
  renderScope(snapshot);
  renderCommands(snapshot);
  renderHumanSummary(snapshot);
  renderStatus(snapshot);
  document.body.classList.add("has-loaded");
}

async function load(options = {}) {
  const fresh = Boolean(options.fresh);
  $("#refreshButton").disabled = true;
  $("#refreshButton").textContent = "Refreshing";
  $("#timestamp").textContent = "Refreshing...";
  $("#main-content").setAttribute("aria-busy", "true");
  setStatusMessage("Refreshing repository snapshot.");
  try {
    const response = await fetch(`/api/snapshot${fresh ? "?fresh=1" : ""}`, { cache: "no-store" });
    if (!response.ok) throw new Error(`snapshot failed: ${response.status}`);
    render(await response.json());
    setStatusMessage(`Dashboard refreshed. Health ${$("#healthGrade").textContent}: ${$("#healthSummary").textContent}`);
  } catch (error) {
    $("#healthGrade").textContent = "Offline";
    $("#healthSummary").textContent = error.message;
    $("#statusOutput").textContent = error.stack || error.message;
    setStatusMessage(`Dashboard snapshot failed: ${error.message}`);
  } finally {
    $("#refreshButton").disabled = false;
    $("#refreshButton").textContent = "Refresh";
    $("#main-content").removeAttribute("aria-busy");
  }
}

function readSavedTheme() {
  try {
    return localStorage.getItem("palari-theme") || "";
  } catch (error) {
    return "";
  }
}

function writeSavedTheme(theme) {
  try {
    localStorage.setItem("palari-theme", theme);
  } catch (error) {
    return;
  }
}

function preferredTheme() {
  const saved = readSavedTheme();
  if (saved === "dark" || saved === "light") return saved;
  return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

function applyTheme(theme) {
  document.body.dataset.theme = theme;
  const button = $("#themeButton");
  const dark = theme === "dark";
  button.setAttribute("aria-pressed", dark ? "true" : "false");
  button.textContent = dark ? "Light" : "Dark";
  setStatusMessage(`${dark ? "Dark" : "Light"} theme enabled`);
}

function toggleTheme() {
  const next = document.body.dataset.theme === "dark" ? "light" : "dark";
  writeSavedTheme(next);
  applyTheme(next);
}

$("#refreshButton").addEventListener("click", () => load({ fresh: true }));
$("#themeButton").addEventListener("click", toggleTheme);
$("#ticketSearch").addEventListener("input", (event) => {
  state.query = event.target.value;
  if (state.snapshot) {
    ensureSelectedTicket(state.snapshot);
    renderQueue(state.snapshot);
    renderTicketRows(state.snapshot);
    renderTicketFocus(state.snapshot);
  }
});
$("#queueFilter").addEventListener("change", (event) => {
  state.queueFilter = event.target.value;
  if (state.snapshot) renderQueue(state.snapshot);
});

applyTheme(preferredTheme());
load();
setInterval(load, 30000);
