const state = {
  snapshot: null,
  surface: "queue",
  queueFilter: "attention",
  query: "",
  selectedTicketId: "",
  deepLinkTicket: (() => {
    try {
      return new URLSearchParams(window.location.search).get("ticket") || "";
    } catch (error) {
      return "";
    }
  })(),
  auto: true,
  autoTimer: null,
  leaseTimer: null,
};

const AUTO_INTERVAL_MS = 15000;
const CHAIN_ORDER = ["implement", "test", "review"];

const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => Array.from(document.querySelectorAll(selector));

const statusLabels = {
  accepted: "Accepted",
  claimed: "Claimed",
  open: "Open",
  "needs-human": "Needs human",
  "in-review": "In review",
  reopened: "Reopened",
  blocked: "Blocked",
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

function formatCountdown(seconds) {
  if (seconds == null || Number.isNaN(seconds)) return "";
  if (seconds <= 0) return "expired";
  const d = Math.floor(seconds / 86400);
  const h = Math.floor((seconds % 86400) / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  if (d > 0) return `${d}d ${h}h`;
  if (h > 0) return `${h}h ${String(m).padStart(2, "0")}m`;
  return m > 0 ? `${m}m ${String(s).padStart(2, "0")}s` : `${s}s`;
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
  (paths || []).slice(0, limit).forEach((path) => {
    const span = document.createElement("span");
    span.textContent = path;
    row.append(span);
  });
  if ((paths || []).length > limit) {
    const span = document.createElement("span");
    span.textContent = `+${paths.length - limit} more`;
    row.append(span);
  }
  return row;
}

// ---------------------------------------------------------------------------
// Derivations

function activeTickets(snapshot) {
  return (snapshot.tickets || []).filter((ticket) => ticket.status !== "accepted");
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

function gateInfo(snapshot) {
  return snapshot?.gate || { enabled: false, available: false, initialized: false, tickets: {} };
}

function gateTicket(snapshot, ticketId) {
  return gateInfo(snapshot).tickets?.[ticketId] || null;
}

function chainSteps(gateTicketInfo) {
  const steps = gateTicketInfo?.steps || {};
  const names = Object.keys(steps);
  const ordered = CHAIN_ORDER.filter((name) => names.includes(name));
  names.forEach((name) => {
    if (!ordered.includes(name)) ordered.push(name);
  });
  return ordered.map((name) => ({ name, ...steps[name] }));
}

function sealState(snapshot, ticket) {
  const gate = gateInfo(snapshot);
  if (!gate.enabled) return { state: "off", text: "honor-system" };
  const info = gateTicket(snapshot, ticket.id);
  if (!info || !info.attested_steps) return { state: "unsigned", text: "unsigned" };
  if (info.verdict?.accepted) return { state: "sealed", text: "sealed" };
  if (info.verdict && !info.verdict.accepted) return { state: "refused", text: "refused" };
  return { state: "partial", text: `${info.attested_steps}/${info.total_steps} signed` };
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
  if (!state.selectedTicketId && state.deepLinkTicket) {
    if (tickets.some((ticket) => ticket.id === state.deepLinkTicket)) {
      state.selectedTicketId = state.deepLinkTicket;
    }
    state.deepLinkTicket = "";
  }
  const visible = searchedTickets(snapshot);
  const pool = visible.length ? visible : tickets;
  const selectedIsVisible = pool.some((ticket) => ticket.id === state.selectedTicketId);
  if (!selectedIsVisible) {
    const ticket = defaultSelectedTicket(pool);
    state.selectedTicketId = ticket?.id || "";
  }
}

function selectedTicket(snapshot) {
  return (snapshot.tickets || []).find((ticket) => ticket.id === state.selectedTicketId) || null;
}

function visibleOrderedTickets(snapshot) {
  if (state.surface === "queue") return queueItems(snapshot);
  return searchedTickets(snapshot);
}

function selectTicket(id, announce = true) {
  state.selectedTicketId = id;
  if (!state.snapshot) return;
  renderSurfaces(state.snapshot);
  renderDossier(state.snapshot);
  if (announce) setStatusMessage(`Selected ticket ${id}`);
}

function moveSelection(delta) {
  if (!state.snapshot) return;
  const tickets = visibleOrderedTickets(state.snapshot);
  if (!tickets.length) return;
  const index = tickets.findIndex((ticket) => ticket.id === state.selectedTicketId);
  const next = tickets[Math.min(tickets.length - 1, Math.max(0, (index < 0 ? 0 : index + delta)))];
  if (next && next.id !== state.selectedTicketId) selectTicket(next.id);
}

// ---------------------------------------------------------------------------
// Shared widgets

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

function commandInline(command, labelText) {
  const row = document.createElement("div");
  row.className = "command-inline";
  const code = document.createElement("code");
  code.textContent = command;
  row.append(code, makeCopyButton(command, labelText));
  return row;
}

function sealMini(snapshot, ticket) {
  const seal = sealState(snapshot, ticket);
  const span = document.createElement("span");
  span.className = `seal-mini ${seal.state}`;
  span.textContent = seal.text;
  span.setAttribute("aria-label", `Evidence seal: ${seal.text}`);
  return span;
}

// ---------------------------------------------------------------------------
// Health model

function healthIssues(snapshot) {
  const issues = [];
  const firstActive = activeTickets(snapshot)[0];
  const ticket = firstActive?.id || "TICKET-ID";
  const gate = gateInfo(snapshot);

  if (gate.enabled && !gate.available) {
    issues.push({
      label: "Gate enabled but kernel unavailable",
      detail: "Acceptance fails closed until python3 with the cryptography package is installed.",
      command: "python3 -c 'import cryptography'",
      severity: "blocked",
    });
  }
  if (gate.enabled && gate.available && !gate.initialized) {
    issues.push({
      label: "Gate not initialized",
      detail: "Create the root and orchestrator keys before signed acceptance can run.",
      command: "./bin/palari gate init",
      severity: "blocked",
    });
  }
  Object.entries(gate.tickets || {}).forEach(([id, info]) => {
    if (info?.verdict && info.verdict.accepted === false) {
      issues.push({
        label: `${id} refused by the gate`,
        detail: info.verdict.reasons?.[0] || "The custody chain does not verify.",
        command: `./bin/palari gate verify ${id}`,
        severity: "blocked",
      });
    }
  });
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
  const sourceDirty = snapshot.health.source_dirty_paths ?? snapshot.health.dirty_paths ?? 0;
  const generatedDirty = snapshot.health.generated_dirty_paths ?? 0;
  if (sourceDirty) {
    issues.push({
      label: `${sourceDirty} source change${sourceDirty > 1 ? "s" : ""} outside the gate`,
      detail: generatedDirty
        ? `${generatedDirty} generated artifact${generatedDirty > 1 ? "s" : ""} also present. Inspect before acceptance or handoff.`
        : "Inspect local changes before acceptance or handoff.",
      command: "./bin/palari hygiene",
      severity: "watch",
    });
  } else if (generatedDirty) {
    issues.push({
      label: `${generatedDirty} generated artifact${generatedDirty > 1 ? "s" : ""}`,
      detail: "Usually cache/build output; confirm it is ignored or clean it before handoff.",
      command: "./bin/palari hygiene",
      severity: "watch",
    });
  }

  return issues;
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
  $("#healthSummary").textContent = issues.length
    ? issues.map((issue) => issue.label).join(" · ")
    : "Workflow, evidence, gate, roles, claims, and scope look clean.";
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
    detail.textContent = "Workflow, evidence, gate, role authority, claims, and scope are clean.";
    node.append(strong, detail);
    list.append(node);
    return;
  }

  issues.forEach((issue) => {
    const node = document.createElement("article");
    node.className = `health-action ${issue.severity}`;
    const strong = document.createElement("strong");
    strong.textContent = issue.label;
    const detail = document.createElement("span");
    detail.textContent = issue.detail;
    node.append(strong, detail, commandInline(issue.command, issue.label));
    list.append(node);
  });
}

// ---------------------------------------------------------------------------
// Header strips

function renderOperatorSummary(snapshot) {
  const action = snapshot.operator?.next_action || {};
  const inboxCounts = snapshot.operator?.inbox_counts || {};
  const waitingHuman = activeTickets(snapshot).filter((ticket) => ticket.next_action?.actor === "human" || ticket.status === "needs-human");
  const roleCount = snapshot.roles?.counts?.active || 0;
  const roleLintOk = snapshot.roles?.lint?.ok !== false;
  const gate = gateInfo(snapshot);

  $("#operatorNext").textContent = action.label || "Inspect repository";
  $("#operatorDetail").textContent = action.detail || "Open the queue for the next ticket action.";
  $("#humanGate").textContent = waitingHuman.length ? `${waitingHuman.length} waiting` : "Clear";
  $("#humanGateDetail").textContent = waitingHuman.length
    ? `${inboxCounts.human_gate || waitingHuman.length} item${(inboxCounts.human_gate || waitingHuman.length) === 1 ? "" : "s"} in Founder Inbox`
    : "No active ticket is waiting on a human decision.";

  if (!gate.enabled) {
    $("#gatePosture").textContent = "Honor-system";
    $("#gatePostureDetail").textContent = "Acceptance trusts unsigned manifests. Enable gate.enabled for forge-proof acceptance.";
  } else if (!gate.available) {
    $("#gatePosture").textContent = "Fails closed";
    $("#gatePostureDetail").textContent = "Gate enabled, kernel unavailable; nothing can be accepted.";
  } else if (!gate.initialized) {
    $("#gatePosture").textContent = "Keys needed";
    $("#gatePostureDetail").textContent = "Run gate init to create the root key.";
  } else {
    const verdicts = Object.values(gate.tickets || {});
    const sealed = verdicts.filter((info) => info?.verdict?.accepted).length;
    $("#gatePosture").textContent = "Forge-proof";
    $("#gatePostureDetail").textContent = `Root ${gate.root_fingerprint}; ${sealed} ticket${sealed === 1 ? "" : "s"} sealed.`;
  }

  $("#roleSystem").textContent = roleLintOk ? `${roleCount} active` : "Needs review";
  $("#roleSystemDetail").textContent = roleLintOk
    ? "Role authority is lint-clean."
    : "Run role lint before trusting delegation.";

  const gateChip = $("#gateChip");
  if (!gate.enabled) {
    gateChip.textContent = "gate off";
    gateChip.dataset.state = "off";
  } else if (!gate.available || !gate.initialized) {
    gateChip.textContent = "gate blocked";
    gateChip.dataset.state = "blocked";
  } else {
    gateChip.textContent = "gate on";
    gateChip.dataset.state = "on";
  }

  const plaque = $("#rootFingerprint");
  const plaqueDetail = $("#rootPlaqueDetail");
  if (gate.enabled && gate.initialized && gate.root_fingerprint) {
    plaque.textContent = gate.root_fingerprint;
    plaqueDetail.textContent = "All custody chains must verify to this key.";
  } else if (gate.enabled) {
    plaque.textContent = "not initialized";
    plaqueDetail.textContent = "Run ./bin/palari gate init to mint it.";
  } else {
    plaque.textContent = "gate disabled";
    plaqueDetail.textContent = "Signed acceptance is off; acceptance is honor-system.";
  }
}

function inboxRank(item) {
  const order = {
    "human-gate": 0,
    blocked: 1,
    "evidence-needed": 2,
    "review-needed": 3,
    "can-continue": 4,
    watch: 5,
    monitor: 6,
  };
  return order[item.category] ?? 9;
}

function renderFounderInbox(snapshot) {
  const list = $("#founderInboxList");
  list.replaceChildren();
  const inbox = [...(snapshot.operator?.inbox || [])].sort((left, right) => inboxRank(left) - inboxRank(right));
  const counts = snapshot.operator?.inbox_counts || {};
  $("#founderInboxPill").textContent = inbox.length
    ? `${inbox.length} decision${inbox.length === 1 ? "" : "s"}`
    : "clear";

  if (!inbox.length) {
    list.append(emptyNode("Nothing needs a decision", "Create or adopt a scoped ticket when there is more work to delegate."));
    return;
  }

  const summary = document.createElement("div");
  summary.className = "inbox-summary";
  [
    ["Human", counts.human_gate || 0],
    ["Blocked", counts.blocked || 0],
    ["Evidence", counts.evidence_needed || 0],
    ["Continue", counts.can_continue || 0],
  ].forEach(([name, value]) => {
    const chip = document.createElement("span");
    chip.textContent = `${name} ${value}`;
    summary.append(chip);
  });
  list.append(summary);

  inbox.slice(0, 6).forEach((item) => {
    const row = document.createElement("article");
    row.className = `inbox-item ${item.category || "monitor"}`;

    const main = document.createElement("div");
    main.className = "inbox-main";
    const category = document.createElement("span");
    category.className = "inbox-category";
    category.textContent = item.category_label || label(item.category);
    const title = document.createElement("button");
    title.className = "inbox-ticket";
    title.type = "button";
    title.textContent = `${item.ticket_id} · ${item.title}`;
    title.addEventListener("click", () => selectTicket(item.ticket_id));
    const detail = document.createElement("p");
    detail.textContent = item.detail || item.label || "Inspect ticket.";
    main.append(category, title, detail);

    row.append(main, severityPill(item.severity || "watch"));
    if (item.command) row.append(commandInline(item.command, item.label || item.ticket_id));
    list.append(row);
  });

  if (inbox.length > 6) {
    const more = document.createElement("p");
    more.className = "inbox-more";
    more.textContent = `${inbox.length - 6} more item${inbox.length - 6 === 1 ? "" : "s"} in the queue and ledger.`;
    list.append(more);
  }
}

function renderMetrics(snapshot) {
  const tickets = snapshot.tickets || [];
  const attention = tickets.filter((ticket) => ticketQueue(ticket) === "attention").length;
  $("#countAttention").textContent = attention;
  $("#countActive").textContent = activeTickets(snapshot).length;
  $("#countReview").textContent = snapshot.counts["in-review"] || 0;
  $("#countAccepted").textContent = snapshot.counts.accepted || 0;
}

// ---------------------------------------------------------------------------
// Surfaces: queue, board, ledger

function queueItems(snapshot) {
  const tickets = searchedTickets(snapshot);
  if (state.queueFilter === "all") return tickets;
  return tickets.filter((ticket) => ticketQueue(ticket) === state.queueFilter);
}

function queueItemNode(snapshot, ticket) {
  const node = document.createElement("article");
  node.className = `queue-item ${ticket.id === state.selectedTicketId ? "selected" : ""}`;
  node.tabIndex = 0;
  node.setAttribute("role", "button");
  node.setAttribute("aria-pressed", ticket.id === state.selectedTicketId ? "true" : "false");

  const top = document.createElement("div");
  top.className = "queue-top";
  const title = document.createElement("strong");
  title.textContent = `${ticket.id} · ${ticket.title}`;
  top.append(title, severityPill(actionSeverity(ticket)));

  const detail = document.createElement("p");
  detail.textContent = ticket.next_action?.label || label(ticket.status);

  node.append(
    top,
    detail,
    meta([label(ticket.status), ticket.risk, ticketOwner(ticket), ticketRole(ticket)]),
  );
  node.append(sealMini(snapshot, ticket));

  const open = () => selectTicket(ticket.id);
  node.addEventListener("click", open);
  node.addEventListener("keydown", (event) => {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      open();
    }
  });
  return node;
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
      ? "Search terms matched tickets, but the current filter hides them. Try All tickets or clear the search."
      : "No tickets match this queue filter. Change the filter or create a scoped ticket.";
    list.append(emptyNode("No matching tickets", detail));
    return;
  }

  tickets.forEach((ticket) => list.append(queueItemNode(snapshot, ticket)));
}

const BOARD_LANES = [
  { key: "open", title: "Open", match: (t) => t.status === "open" },
  { key: "progress", title: "In progress", match: (t) => ["claimed", "reopened"].includes(t.status) },
  { key: "review", title: "Review", match: (t) => t.status === "in-review" },
  { key: "human", title: "Needs human", match: (t) => ["needs-human", "blocked"].includes(t.status) },
  { key: "done", title: "Accepted", match: (t) => t.status === "accepted" },
];

function boardCard(snapshot, ticket) {
  const node = document.createElement("article");
  node.className = `board-card ${ticket.id === state.selectedTicketId ? "selected" : ""}`;
  node.tabIndex = 0;
  node.setAttribute("role", "button");
  const id = document.createElement("code");
  id.textContent = ticket.id;
  const title = document.createElement("strong");
  title.textContent = ticket.title;
  node.append(id, title, meta([ticket.risk, ticketOwner(ticket)]), sealMini(snapshot, ticket));
  const open = () => selectTicket(ticket.id);
  node.addEventListener("click", open);
  node.addEventListener("keydown", (event) => {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      open();
    }
  });
  return node;
}

function renderBoard(snapshot) {
  const lanes = $("#boardLanes");
  lanes.replaceChildren();
  const tickets = searchedTickets(snapshot);
  $("#boardPill").textContent = `${tickets.length} ticket${tickets.length === 1 ? "" : "s"}`;
  BOARD_LANES.forEach((lane) => {
    const column = document.createElement("section");
    column.className = `board-lane lane-${lane.key}`;
    const head = document.createElement("header");
    const title = document.createElement("h3");
    title.textContent = lane.title;
    const count = document.createElement("span");
    const matching = tickets.filter(lane.match);
    count.textContent = matching.length;
    head.append(title, count);
    column.append(head);
    if (!matching.length) {
      const quiet = document.createElement("p");
      quiet.className = "lane-empty";
      quiet.textContent = "Empty";
      column.append(quiet);
    }
    matching.forEach((ticket) => column.append(boardCard(snapshot, ticket)));
    lanes.append(column);
  });
}

function renderLedger(snapshot) {
  const rows = $("#ticketRows");
  rows.replaceChildren();
  const tickets = searchedTickets(snapshot);
  $("#ticketPill").textContent = `${tickets.length} ticket${tickets.length === 1 ? "" : "s"}`;

  if (!tickets.length) {
    const row = document.createElement("tr");
    const cell = document.createElement("td");
    cell.colSpan = 6;
    cell.append(emptyNode("No tickets", "Create a scoped ticket or clear the search."));
    row.append(cell);
    rows.append(row);
    return;
  }

  tickets.forEach((ticket) => {
    const row = document.createElement("tr");
    if (ticket.id === state.selectedTicketId) row.className = "selected";

    const idCell = document.createElement("td");
    idCell.dataset.label = "Ticket";
    const link = document.createElement("button");
    link.type = "button";
    link.className = "ticket-link";
    const code = document.createElement("code");
    code.textContent = ticket.id;
    const title = document.createElement("span");
    title.textContent = ticket.title;
    link.append(code, title);
    link.addEventListener("click", () => selectTicket(ticket.id));
    idCell.append(link);

    const ownerCell = document.createElement("td");
    ownerCell.dataset.label = "Owner";
    ownerCell.textContent = ticketOwner(ticket);

    const riskCell = document.createElement("td");
    riskCell.dataset.label = "Risk";
    riskCell.textContent = `${ticket.risk || "R1"} · ${ticket.priority || "P2"}`;

    const stageCell = document.createElement("td");
    stageCell.dataset.label = "Stage";
    stageCell.append(statusPill(ticket.status));

    const sealCell = document.createElement("td");
    sealCell.dataset.label = "Seal";
    sealCell.append(sealMini(snapshot, ticket));

    const nextCell = document.createElement("td");
    nextCell.dataset.label = "Next";
    nextCell.textContent = ticket.next_action?.label || "";

    row.append(idCell, ownerCell, riskCell, stageCell, sealCell, nextCell);
    rows.append(row);
  });
}

function setSurface(surface, announce = true) {
  state.surface = surface;
  $$(".surface-tabs [role='tab']").forEach((tab) => {
    const active = tab.dataset.surface === surface;
    tab.setAttribute("aria-selected", active ? "true" : "false");
  });
  $("#queue").hidden = surface !== "queue";
  $("#board").hidden = surface !== "board";
  $("#ledger").hidden = surface !== "ledger";
  if (announce) setStatusMessage(`Showing the ${surface} surface`);
}

function renderSurfaces(snapshot) {
  renderQueue(snapshot);
  renderBoard(snapshot);
  renderLedger(snapshot);
}

// ---------------------------------------------------------------------------
// Dossier: ticket focus + chain of custody

function readiness(snapshot, ticket) {
  const evidence = ticket.evidence || {};
  const reports = ticket.reports || {};
  const evidenceOk = Boolean(evidence.has_log && evidence.has_junit && evidence.has_sarif && evidence.has_manifest);
  const missing = ["log", "junit", "sarif", "manifest"].filter((name, index) => !evidence[["has_log", "has_junit", "has_sarif", "has_manifest"][index]]);
  const customMissing = (reports.custom || []).filter((entry) => !entry.present).map((entry) => entry.name);
  const reportsOk = Boolean(reports.technical) && !customMissing.length;
  const reportDetail = !reports.technical
    ? "technical report missing"
    : customMissing.length
      ? `missing: ${customMissing.join(", ")}`
      : reports.reviewer
        ? "technical + reviewer present"
        : "technical present";
  const rows = [
    { label: "Evidence bundle", ok: evidenceOk, detail: evidenceOk ? "manifest, junit, sarif, log" : `missing ${missing.join(", ")}` },
    { label: "Reports", ok: reportsOk, detail: reportDetail },
    { label: "Lease", ok: ticket.lease?.status !== "expired", detail: ticket.lease?.status === "expired" ? "claim expired" : (ticket.lease?.status || "none") },
  ];
  // Executor refusal evidence: when an executor ran and a gate refused it,
  // surface the refusal as preserved evidence instead of an empty bundle.
  for (const run of evidence.executor_evidence || []) {
    const refused = run.scope_check_exit !== null && run.scope_check_exit !== 0;
    const ciFailed = run.ci_exit !== null && run.ci_exit !== 0;
    const detailParts = [
      `executor: ${run.executor}`,
      `run: ${run.run_exit === 0 ? "completed" : `exit ${run.run_exit}`}`,
      refused ? "scope-check: refused" : run.scope_check_exit === 0 ? "scope-check: passed" : null,
      ciFailed ? "ci: failed" : null,
      run.model ? `model: ${run.model.split("\n")[0].replace(/^model: /, "")}` : null,
      `evidence: ${run.path}`,
    ].filter(Boolean);
    rows.push({
      label: refused ? "Executor refusal evidence" : "Executor evidence",
      ok: !refused && !ciFailed,
      detail: detailParts.join(" · "),
    });
  }
  return rows;
}

function renderTicketFocus(snapshot) {
  const focus = $("#ticketFocus");
  focus.replaceChildren();
  const ticket = selectedTicket(snapshot);
  $("#focusPill").textContent = ticket ? ticket.id : "ticket";

  if (!ticket) {
    focus.append(emptyNode("No ticket selected", "Pick a ticket from the queue, board, or ledger."));
    return;
  }

  const head = document.createElement("div");
  head.className = "focus-head";
  const title = document.createElement("h3");
  title.textContent = `${ticket.id} · ${ticket.title}`;
  head.append(title, statusPill(ticket.status));
  focus.append(head);

  const lease = ticket.lease || {};
  const leaseText = lease.status === "active"
    ? `lease ${formatCountdown(Number(lease.seconds_remaining))}`
    : lease.status === "expired"
      ? "lease expired"
      : "";
  focus.append(meta([
    `owner ${ticketOwner(ticket)}`,
    ticketRole(ticket),
    `${ticket.risk || "R1"} · ${ticket.priority || "P2"}`,
    ticket.stream,
    leaseText,
  ]));
  if (lease.status === "active") {
    const tickNode = focus.querySelector(".meta span:last-child");
    if (tickNode) {
      tickNode.classList.add("lease-tick");
      tickNode.dataset.expiresAt = lease.expires_at || "";
    }
  }

  const branch = document.createElement("div");
  branch.className = "focus-branch";
  const branchCode = document.createElement("code");
  branchCode.textContent = ticket.branch || "";
  branch.append(branchCode);
  focus.append(branch);

  const grid = document.createElement("div");
  grid.className = "readiness-grid";
  readiness(snapshot, ticket).forEach((item) => {
    const cell = document.createElement("article");
    cell.className = `readiness ${item.ok ? "ok" : "bad"}`;
    const strong = document.createElement("strong");
    strong.textContent = item.label;
    const detail = document.createElement("span");
    detail.textContent = item.detail;
    cell.append(strong, detail);
    grid.append(cell);
  });
  focus.append(grid);

  const scopes = document.createElement("div");
  scopes.className = "focus-scope";
  const scopeTitle = document.createElement("p");
  scopeTitle.className = "eyebrow";
  scopeTitle.textContent = "Allowed paths";
  scopes.append(scopeTitle, pathList(ticket.allowed_paths || [], 4));
  focus.append(scopes);
}

function custodyNode(step) {
  const node = document.createElement("li");
  node.className = `custody-step ${step.attested ? "sealed" : "open"}`;
  const disc = document.createElement("span");
  disc.className = "seal-disc";
  disc.setAttribute("aria-hidden", "true");
  const body = document.createElement("div");
  body.className = "custody-body";
  const name = document.createElement("strong");
  name.textContent = step.name;
  body.append(name);
  if (step.attested) {
    const signer = document.createElement("code");
    signer.textContent = `key ${step.signer}`;
    body.append(signer);
    const detail = document.createElement("span");
    const when = step.ts ? new Date(step.ts) : null;
    const stamp = when && !Number.isNaN(when.getTime()) ? when.toISOString().slice(0, 16).replace("T", " ") : "";
    detail.textContent = [
      step.signature_valid === false ? "signature INVALID" : "signature verified",
      stamp,
      (step.outputs || []).length ? `outputs: ${(step.outputs || []).join(", ")}` : "",
    ].filter(Boolean).join(" · ");
    body.append(detail);
  } else {
    const detail = document.createElement("span");
    detail.textContent = "not attested yet";
    body.append(detail);
  }
  node.append(disc, body);
  return node;
}

function renderCustody(snapshot) {
  const wrap = $("#custody");
  wrap.replaceChildren();
  const ticket = selectedTicket(snapshot);
  if (!ticket) return;
  const gate = gateInfo(snapshot);

  const head = document.createElement("div");
  head.className = "custody-head";
  const title = document.createElement("h3");
  title.textContent = "Chain of Custody";
  head.append(title);
  wrap.append(head);

  if (!gate.enabled) {
    const off = document.createElement("div");
    off.className = "verdict-stamp off";
    const strong = document.createElement("strong");
    strong.textContent = "Honor-system";
    const detail = document.createElement("span");
    detail.textContent = "The forge-proof gate is disabled; acceptance trusts unsigned manifests.";
    off.append(strong, detail);
    wrap.append(off, commandInline("./bin/palari gate init", "Initialize the gate"));
    return;
  }

  const info = gateTicket(snapshot, ticket.id);
  const steps = info ? chainSteps(info) : CHAIN_ORDER.map((name) => ({ name, attested: false }));

  const list = document.createElement("ol");
  list.className = "custody-chain";
  steps.forEach((step) => list.append(custodyNode(step)));
  wrap.append(list);

  const verdict = info?.verdict;
  const stamp = document.createElement("div");
  if (verdict?.accepted) {
    stamp.className = "verdict-stamp accepted";
    const strong = document.createElement("strong");
    strong.textContent = "ACCEPTED";
    const detail = document.createElement("span");
    detail.textContent = `Verified to root ${gate.root_fingerprint} at commit ${verdict.commit}.`;
    stamp.append(strong, detail);
  } else if (verdict) {
    stamp.className = "verdict-stamp refused";
    const strong = document.createElement("strong");
    strong.textContent = "REFUSED";
    stamp.append(strong);
    const reasons = document.createElement("ul");
    reasons.className = "verdict-reasons";
    (verdict.reasons || []).forEach((reason) => {
      const item = document.createElement("li");
      item.textContent = reason;
      reasons.append(item);
    });
    stamp.append(reasons);
  } else {
    stamp.className = "verdict-stamp unsigned";
    const strong = document.createElement("strong");
    strong.textContent = "UNSIGNED";
    const detail = document.createElement("span");
    detail.textContent = "No attestations yet. The gate will refuse acceptance until the chain is complete.";
    stamp.append(strong, detail);
  }
  wrap.append(stamp);

  if (!verdict?.accepted) {
    const next = !info || !info.steps?.implement?.attested
      ? `./bin/palari gate setup-ticket ${ticket.id} && ./bin/palari gate attest-implement ${ticket.id}`
      : !info.steps?.test?.attested
        ? `./bin/palari ci ${ticket.id}`
        : `./bin/palari gate attest-review ${ticket.id}`;
    wrap.append(commandInline(next, "Next custody step"));
  }
}

function renderCommands(snapshot) {
  const list = $("#commandList");
  list.replaceChildren();
  const ticket = selectedTicket(snapshot);
  const commands = [];
  if (ticket?.next_action?.command) {
    commands.push({ label: ticket.next_action.label, command: ticket.next_action.command });
  }
  if (ticket) {
    commands.push({ label: "Verify custody chain", command: `./bin/palari gate verify ${ticket.id}` });
    commands.push({ label: "Inspect ticket", command: `./bin/palari lint ${ticket.id}` });
  }
  const operator = snapshot.operator?.next_action;
  if (!commands.length && operator?.command) {
    commands.push({ label: operator.label, command: operator.command });
  }
  if (!commands.length) {
    list.append(emptyNode("No command needed", "The repository is waiting on new work."));
    return;
  }
  commands.forEach((entry) => {
    const node = document.createElement("article");
    node.className = "command-entry";
    const strong = document.createElement("strong");
    strong.textContent = entry.label || "Command";
    node.append(strong, commandInline(entry.command, entry.label || "Command"));
    list.append(node);
  });
}

function renderDossier(snapshot) {
  renderTicketFocus(snapshot);
  renderCustody(snapshot);
  renderCommands(snapshot);
}

// ---------------------------------------------------------------------------
// Support panels

function renderRoles(snapshot) {
  const list = $("#roleList");
  list.replaceChildren();
  const roles = snapshot.roles?.items || [];
  const active = roles.filter((role) => role.status === "active");
  $("#rolesPill").textContent = `${active.length} active`;
  if (!roles.length) {
    list.append(emptyNode("No roles installed", "Roles are optional; tickets work without them."));
    return;
  }
  roles.forEach((role) => {
    const row = document.createElement("article");
    row.className = "role-row";
    const head = document.createElement("div");
    head.className = "role-head";
    const name = document.createElement("strong");
    name.textContent = role.id;
    head.append(name, statusPill(role.status));
    const detail = document.createElement("span");
    detail.textContent = [role.title, role.tier, role.max_risk].filter(Boolean).join(" · ");
    row.append(head, detail, pathList(role.allowed_paths || [], 2));
    list.append(row);
  });
}

function renderScope(snapshot) {
  const map = $("#scopeMap");
  map.replaceChildren();
  const overlaps = snapshot.overlaps || [];
  $("#scopePill").textContent = overlaps.length ? `${overlaps.length} overlap${overlaps.length === 1 ? "" : "s"}` : "clean";
  $("#scopePill").dataset.state = overlaps.length ? "bad" : "ok";
  const tickets = activeTickets(snapshot);
  if (!tickets.length) {
    map.append(emptyNode("No active scopes", "Active tickets will show their write partitions here."));
    return;
  }
  tickets.forEach((ticket) => {
    const row = document.createElement("article");
    row.className = "scope-row";
    const head = document.createElement("div");
    head.className = "scope-head";
    const code = document.createElement("code");
    code.textContent = ticket.id;
    head.append(code);
    const conflicting = overlaps.filter((o) => o.left === ticket.id || o.right === ticket.id);
    if (conflicting.length) {
      const warn = document.createElement("span");
      warn.className = "scope-warn";
      warn.textContent = "overlap";
      head.append(warn);
    }
    row.append(head, pathList(ticket.allowed_paths || [], 3));
    map.append(row);
  });
}

function renderHuman(snapshot) {
  const wrap = $("#humanSummary");
  wrap.replaceChildren();
  const waiting = activeTickets(snapshot).filter((ticket) => ticket.next_action?.actor === "human" || ticket.status === "needs-human" || ticket.status === "in-review");
  $("#humanPill").textContent = waiting.length ? `${waiting.length} waiting` : "ready";
  if (!waiting.length) {
    wrap.append(emptyNode("Nothing awaits a human", "Acceptance and direction decisions will surface here."));
    return;
  }
  waiting.forEach((ticket) => {
    const row = document.createElement("article");
    row.className = "human-row";
    const head = document.createElement("div");
    head.className = "human-head";
    const code = document.createElement("code");
    code.textContent = ticket.id;
    head.append(code, sealMini(snapshot, ticket));
    const detail = document.createElement("span");
    detail.textContent = ticket.next_action?.detail || label(ticket.status);
    row.append(head, detail);
    if (ticket.next_action?.command) row.append(commandInline(ticket.next_action.command, ticket.id));
    wrap.append(row);
  });
}

function companyMetric(labelText, value, detail = "") {
  const node = document.createElement("article");
  node.className = "company-metric";
  const labelNode = document.createElement("span");
  labelNode.textContent = labelText;
  const strong = document.createElement("strong");
  strong.textContent = value;
  node.append(labelNode, strong);
  if (detail) {
    const small = document.createElement("small");
    small.textContent = detail;
    node.append(small);
  }
  return node;
}

function gatePill(gate) {
  const span = document.createElement("span");
  span.className = "company-gate";
  span.dataset.state = gate || "green";
  span.textContent = gate || "green";
  return span;
}

function renderCompanyGovernance(snapshot) {
  const company = snapshot.company_os || {};
  const workflows = company.workflows || { active: 0, proposed: 0, closed: 0, items: [] };
  const humans = company.humans || { active: 0 };
  const governance = company.human_governance || {};
  const autonomy = company.autonomy || {};
  const summary = $("#companyGovernanceSummary");
  const list = $("#companyWorkflowList");
  summary.replaceChildren();
  list.replaceChildren();

  const active = workflows.active || 0;
  $("#companyGovernancePill").textContent = `${active} active`;
  $("#companyGovernancePill").dataset.state = (autonomy.red_workflows || 0) ? "bad" : "ok";

  summary.append(
    companyMetric("Workflows", String(active), `${workflows.proposed || 0} proposed / ${workflows.closed || 0} closed`),
    companyMetric("Open HGL", String(governance.open_hgl_estimate || 0), `${humans.active || 0} active human profile${humans.active === 1 ? "" : "s"}`),
    companyMetric("R3/R4/R5", `${governance.r3_decisions_open || 0}/${governance.r4_decisions_open || 0}/${governance.r5_decisions_open || 0}`),
    companyMetric("Missing skills", String((governance.missing_skills || []).length), (governance.missing_skills || []).slice(0, 2).join(", "))
  );

  if (!active) {
    list.append(emptyNode("No active workflows", "Adopt a workflow to see HGL, launch gates, and autonomy posture here."));
    return;
  }

  (workflows.items || []).slice(0, 5).forEach((workflow) => {
    const row = document.createElement("article");
    row.className = "company-workflow-row";
    const head = document.createElement("div");
    head.className = "company-workflow-head";
    const code = document.createElement("code");
    code.textContent = workflow.id;
    const title = document.createElement("strong");
    title.textContent = workflow.title || "Untitled workflow";
    head.append(code, title, gatePill(workflow.launch_gate));
    const detail = document.createElement("span");
    detail.textContent = `HGL ${workflow.human_governance_load || 0} · ${workflow.autonomy_ceiling || "unknown"} · ${workflow.risk_ceiling || "risk"}`;
    row.append(head, detail);
    list.append(row);
  });
}

function renderRepo(snapshot) {
  $("#branchPill").textContent = snapshot.git?.branch || "detached";
  $("#statusOutput").textContent = snapshot.git?.status || "clean";
  $("#projectName").textContent = snapshot.project || "Palari Orchestrator";
  $("#railProject").textContent = snapshot.project || "Orchestration";
  $("#authorityChip").textContent = snapshot.authority?.profile || "authority";
}

// ---------------------------------------------------------------------------
// Lease ticking

function startLeaseTicker() {
  if (state.leaseTimer) clearInterval(state.leaseTimer);
  state.leaseTimer = setInterval(() => {
    $$(".lease-tick").forEach((node) => {
      const expires = node.dataset.expiresAt;
      if (!expires) return;
      const remaining = Math.floor((new Date(expires).getTime() - Date.now()) / 1000);
      node.textContent = remaining <= 0 ? "lease expired" : `lease ${formatCountdown(remaining)}`;
      node.classList.toggle("expired", remaining <= 0);
    });
  }, 1000);
}

// ---------------------------------------------------------------------------
// Snapshot lifecycle

function render(snapshot) {
  state.snapshot = snapshot;
  ensureSelectedTicket(snapshot);
  health(snapshot);
  renderMetrics(snapshot);
  renderOperatorSummary(snapshot);
  renderFounderInbox(snapshot);
  renderSurfaces(snapshot);
  renderDossier(snapshot);
  renderHealthActions(snapshot);
  renderRoles(snapshot);
  renderScope(snapshot);
  renderHuman(snapshot);
  renderCompanyGovernance(snapshot);
  renderRepo(snapshot);
  $("#timestamp").textContent = formatTimestamp(snapshot.generated_at);
}

async function fetchSnapshot(options = {}) {
  const fresh = Boolean(options.fresh);
  const quiet = Boolean(options.quiet);
  const button = $("#refreshButton");
  if (!quiet) {
    button.disabled = true;
    button.textContent = "Refreshing";
    $("#timestamp").textContent = "Refreshing...";
    setStatusMessage("Refreshing repository snapshot.");
  }
  try {
    const response = await fetch(`/api/snapshot${fresh ? "?fresh=1" : ""}`, { cache: "no-store" });
    if (!response.ok) throw new Error(`snapshot ${response.status}`);
    const snapshot = await response.json();
    render(snapshot);
    if (!quiet) {
      setStatusMessage(`Console refreshed. Health ${$("#healthGrade").textContent}: ${$("#healthSummary").textContent}`);
    }
  } catch (error) {
    $("#railState").textContent = "Error";
    $("#railDetail").textContent = error.message;
    $("#timestamp").textContent = "Refresh failed";
    setStatusMessage(`Refresh failed: ${error.message}. Retry with the Refresh button.`);
  } finally {
    button.disabled = false;
    button.textContent = "Refresh";
  }
}

function scheduleAuto() {
  if (state.autoTimer) clearInterval(state.autoTimer);
  state.autoTimer = setInterval(() => {
    if (!state.auto || document.hidden) return;
    fetchSnapshot({ quiet: true });
  }, AUTO_INTERVAL_MS);
}

// ---------------------------------------------------------------------------
// Theme

function applyTheme(theme) {
  document.body.dataset.theme = theme;
  const button = $("#themeButton");
  button.setAttribute("aria-pressed", theme === "dark" ? "true" : "false");
  button.textContent = theme === "dark" ? "Light" : "Dark";
  try {
    localStorage.setItem("palari-console-theme", theme);
  } catch (error) {
    // Storage can be unavailable; the theme still applies for this session.
  }
}

function initTheme() {
  let theme = "";
  try {
    theme = new URLSearchParams(window.location.search).get("theme") || "";
  } catch (error) {
    theme = "";
  }
  if (!theme) {
    try {
      theme = localStorage.getItem("palari-console-theme") || "";
    } catch (error) {
      theme = "";
    }
  }
  if (!theme) {
    theme = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }
  applyTheme(theme);
}

// ---------------------------------------------------------------------------
// Wiring

function initEvents() {
  $("#refreshButton").addEventListener("click", () => fetchSnapshot({ fresh: true }));
  $("#themeButton").addEventListener("click", () => {
    applyTheme(document.body.dataset.theme === "dark" ? "light" : "dark");
  });
  $("#autoButton").addEventListener("click", () => {
    state.auto = !state.auto;
    const button = $("#autoButton");
    button.setAttribute("aria-pressed", state.auto ? "true" : "false");
    button.textContent = state.auto ? "Auto 15s" : "Auto off";
    setStatusMessage(state.auto ? "Auto refresh on." : "Auto refresh off.");
  });
  $("#ticketSearch").addEventListener("input", (event) => {
    state.query = event.target.value;
    if (state.snapshot) {
      ensureSelectedTicket(state.snapshot);
      renderSurfaces(state.snapshot);
      renderDossier(state.snapshot);
    }
  });
  $("#queueFilter").addEventListener("change", (event) => {
    state.queueFilter = event.target.value;
    if (state.snapshot) renderQueue(state.snapshot);
  });
  $$(".surface-tabs [role='tab']").forEach((tab) => {
    tab.addEventListener("click", () => setSurface(tab.dataset.surface));
  });

  document.addEventListener("keydown", (event) => {
    const target = event.target;
    const typing = target instanceof HTMLInputElement || target instanceof HTMLSelectElement || target instanceof HTMLTextAreaElement;
    if (event.key === "Escape" && typing) {
      target.blur();
      return;
    }
    if (typing) return;
    if (event.key === "/") {
      event.preventDefault();
      $("#ticketSearch").focus();
    } else if (event.key === "j") {
      moveSelection(1);
    } else if (event.key === "k") {
      moveSelection(-1);
    } else if (event.key === "1") {
      setSurface("queue");
    } else if (event.key === "2") {
      setSurface("board");
    } else if (event.key === "3") {
      setSurface("ledger");
    } else if (event.key === "t") {
      applyTheme(document.body.dataset.theme === "dark" ? "light" : "dark");
    }
  });

  document.addEventListener("visibilitychange", () => {
    if (!document.hidden && state.auto) fetchSnapshot({ quiet: true });
  });
}

initTheme();
initEvents();
setSurface("queue", false);
fetchSnapshot();
scheduleAuto();
startLeaseTicker();
