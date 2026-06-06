const state = {
  snapshot: null,
  filter: "all",
};

const $ = (selector) => document.querySelector(selector);

const statusLabels = {
  "needs-human": "Needs human",
  "in-review": "In review",
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

function emptyNode(message = "No records yet", detail = "The console will populate as the repository changes.") {
  const template = $("#emptyTemplate").content.cloneNode(true);
  template.querySelector("strong").textContent = message;
  template.querySelector("span").textContent = detail;
  return template;
}

function statusPill(status) {
  const span = document.createElement("span");
  span.className = `status ${status || "open"}`;
  span.textContent = label(status);
  span.setAttribute("aria-label", `Status: ${span.textContent}`);
  return span;
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

function pathList(paths, limit = 4) {
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

function renderMetrics(snapshot) {
  $("#countOpen").textContent = snapshot.counts.open || 0;
  $("#countClaimed").textContent = snapshot.counts.claimed || 0;
  $("#countReview").textContent = snapshot.counts["in-review"] || 0;
  $("#countAccepted").textContent = snapshot.counts.accepted || 0;
}

function healthIssues(snapshot) {
  const issues = [];
  const firstActive = snapshot.tickets.find((ticket) => ticket.status !== "accepted");
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
  button.setAttribute("aria-label", `${labelText}: ${command}`);
  button.addEventListener("click", async () => {
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
  $("#healthSummary").textContent = issues.length ? issues.map((issue) => issue.label).join(" · ") : "Workflow, evidence, claims, and scope look clean.";
  $("#railState").textContent = grade;
  $("#railDetail").textContent = issues.length ? issues[0].label : "Governance model is clean";
}

function renderHealthActions(snapshot) {
  const list = $("#healthActionsList");
  list.replaceChildren();
  const issues = healthIssues(snapshot);

  if (!issues.length) {
    const node = document.createElement("article");
    node.className = "health-action clear";
    const strong = document.createElement("strong");
    strong.textContent = "No action required";
    const detail = document.createElement("span");
    detail.textContent = "Workflow, evidence, claims, and scope are in a clean state.";
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

function renderTickets(snapshot) {
  const list = $("#ticketList");
  list.replaceChildren();
  const tickets = snapshot.tickets.filter((ticket) => state.filter === "all" || ticket.status === state.filter);

  if (!tickets.length) {
    list.append(emptyNode("No matching tickets", "Change the filter or create a scoped ticket."));
    return;
  }

  tickets.forEach((ticket) => {
    const node = document.createElement("article");
    node.className = "ticket";
    node.setAttribute("aria-label", `${ticket.id} ${ticket.title}, status ${label(ticket.status)}`);

    const top = document.createElement("div");
    top.className = "ticket-top";
    const title = document.createElement("div");
    const strong = document.createElement("strong");
    strong.textContent = `${ticket.id} · ${ticket.title}`;
    title.append(strong);
    title.append(meta([ticket.stream, ticket.risk, ticket.priority, ticket.claimed_by && `claimed by ${ticket.claimed_by}`]));
    top.append(title, statusPill(ticket.status));

    const lease = ticket.lease.status !== "none" ? `lease ${ticket.lease.status}` : "";
    node.append(top);
    node.append(meta([ticket.path, ticket.branch, lease]));
    node.append(pathList(ticket.allowed_paths || []));
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
    list.append(emptyNode("No evidence bundles", "Run palari ci TICKET-ID to create logs, JUnit, and SARIF."));
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
    const evidenceState = ticket.evidence.file_count > 0 ? `${ticket.evidence.file_count} files` : "missing evidence";
    title.append(strong);
    title.append(meta([ticket.evidence.path || "reports/evidence", evidenceState]));
    top.append(title, ticket.evidence.file_count > 0 ? statusPill(ticket.status) : statusPill("blocked"));

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
      const action = document.createElement("div");
      action.className = "evidence-action";
      const code = document.createElement("code");
      code.textContent = command;
      action.append(code, makeCopyButton(command, `Create evidence for ${ticket.id}`));
      node.append(action);
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
  const firstActive = snapshot.tickets.find((ticket) => ticket.status !== "accepted");
  const ticket = firstActive?.id || "TICKET-ID";
  return [
    ["Status", "./bin/palari status"],
    ["Lint", `./bin/palari lint ${firstActive ? ticket : ""}`.trim()],
    ["Scope", `./bin/palari scope-check ${ticket}`],
    ["CI evidence", `./bin/palari ci ${ticket} --base ${snapshot.config.default_branch}`],
    ["Reviewer packet", `./bin/palari packet ${ticket} reviewer`],
    ["Ruleset activation", "./bin/palari github ruleset-command --repo OWNER/REPO"],
  ];
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

function renderStatus(snapshot) {
  $("#branchPill").textContent = snapshot.git.branch;
  const palari = snapshot.palari_status.stdout || snapshot.palari_status.stderr || "No palari status output.";
  const git = snapshot.git.status || "No git status output.";
  $("#statusOutput").textContent = `${palari}\n\n${git}`;
}

function render(snapshot) {
  state.snapshot = snapshot;
  $("#projectName").textContent = snapshot.project;
  $("#timestamp").textContent = formatTimestamp(snapshot.generated_at);
  $("#timestamp").title = `Updated ${snapshot.generated_at}`;
  renderMetrics(snapshot);
  health(snapshot);
  renderHealthActions(snapshot);
  renderTickets(snapshot);
  renderEvidence(snapshot);
  renderScope(snapshot);
  renderCommands(snapshot);
  renderStatus(snapshot);
  document.body.classList.add("has-loaded");
}

function updateActiveNavigation() {
  const current = window.location.hash || "#overview";
  document.querySelectorAll("nav a[href^='#']").forEach((link) => {
    const isActive = link.getAttribute("href") === current;
    link.classList.toggle("active", isActive);
    if (isActive) {
      link.setAttribute("aria-current", "page");
    } else {
      link.removeAttribute("aria-current");
    }
  });
}

async function load(options = {}) {
  const fresh = Boolean(options.fresh);
  $("#refreshButton").disabled = true;
  $("#main-content").setAttribute("aria-busy", "true");
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
    $("#main-content").removeAttribute("aria-busy");
  }
}

$("#refreshButton").addEventListener("click", () => load({ fresh: true }));
$("#ticketFilter").addEventListener("change", (event) => {
  state.filter = event.target.value;
  if (state.snapshot) renderTickets(state.snapshot);
});
window.addEventListener("hashchange", updateActiveNavigation);

updateActiveNavigation();
load();
setInterval(load, 30000);
