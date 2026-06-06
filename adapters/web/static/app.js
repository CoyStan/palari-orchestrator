const state = {
  snapshot: null,
  filter: "all",
};

const $ = (selector) => document.querySelector(selector);

const statusLabels = {
  "needs-human": "Needs human",
  "in-review": "In review",
};

function label(value) {
  return statusLabels[value] || String(value || "unknown").replace(/^\w/, (match) => match.toUpperCase());
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

function health(snapshot) {
  const issues = [];
  if (!snapshot.workflow.workflow_installed) issues.push("workflow missing");
  if (!snapshot.workflow.ruleset_template) issues.push("ruleset template missing");
  if (!snapshot.workflow.attestation) issues.push("attestation missing");
  if (snapshot.health.overlaps) issues.push(`${snapshot.health.overlaps} overlap${snapshot.health.overlaps > 1 ? "s" : ""}`);
  if (snapshot.health.stale_claims) issues.push(`${snapshot.health.stale_claims} stale claim${snapshot.health.stale_claims > 1 ? "s" : ""}`);
  if (snapshot.health.dirty_paths) issues.push(`${snapshot.health.dirty_paths} changed path${snapshot.health.dirty_paths > 1 ? "s" : ""}`);

  const grade = issues.length === 0 ? "Clear" : issues.length < 3 ? "Watch" : "Blocked";
  $("#healthGrade").textContent = grade;
  $("#healthSummary").textContent = issues.length ? issues.join(" · ") : "Workflow, evidence, claims, and scope look clean.";
  $("#railState").textContent = grade;
  $("#railDetail").textContent = issues.length ? issues[0] : "Governance model is clean";
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
  const tickets = snapshot.tickets.filter((ticket) => ticket.evidence.file_count > 0);
  $("#evidencePill").textContent = `${tickets.length} bundle${tickets.length === 1 ? "" : "s"}`;

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
    title.append(strong);
    title.append(meta([ticket.evidence.path, `${ticket.evidence.file_count} files`]));
    top.append(title, statusPill(ticket.status));

    const grid = document.createElement("div");
    grid.className = "evidence-grid";
    [
      ["Log", ticket.evidence.has_log],
      ["JUnit", ticket.evidence.has_junit],
      ["SARIF", ticket.evidence.has_sarif],
    ].forEach(([name, yes]) => {
      const span = document.createElement("span");
      span.className = yes ? "yes" : "";
      span.textContent = `${name}: ${yes ? "present" : "missing"}`;
      grid.append(span);
    });

    node.append(top, grid);
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
    clean.innerHTML = "<span>No overlapping active write scopes</span><i class=\"connector\"></i><span>Path partitioning is clean</span>";
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
    const button = document.createElement("button");
    button.className = "copy";
    button.type = "button";
    button.textContent = "Copy";
    button.addEventListener("click", async () => {
      await navigator.clipboard.writeText(command);
      button.textContent = "Copied";
      setTimeout(() => {
        button.textContent = "Copy";
      }, 1100);
    });
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
  $("#timestamp").textContent = `Updated ${snapshot.generated_at}`;
  renderMetrics(snapshot);
  health(snapshot);
  renderTickets(snapshot);
  renderEvidence(snapshot);
  renderScope(snapshot);
  renderCommands(snapshot);
  renderStatus(snapshot);
}

async function load() {
  $("#refreshButton").disabled = true;
  try {
    const response = await fetch("/api/snapshot", { cache: "no-store" });
    if (!response.ok) throw new Error(`snapshot failed: ${response.status}`);
    render(await response.json());
  } catch (error) {
    $("#healthGrade").textContent = "Offline";
    $("#healthSummary").textContent = error.message;
    $("#statusOutput").textContent = error.stack || error.message;
  } finally {
    $("#refreshButton").disabled = false;
  }
}

$("#refreshButton").addEventListener("click", load);
$("#ticketFilter").addEventListener("change", (event) => {
  state.filter = event.target.value;
  if (state.snapshot) renderTickets(state.snapshot);
});

load();
setInterval(load, 30000);
