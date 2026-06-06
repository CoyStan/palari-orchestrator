#!/usr/bin/env python3
"""Repo-native memory helper for Palari.

Markdown files under memory/**/*.md are the source of truth. SQLite and JSON
files under .palari/cache are generated read models only.
"""

from __future__ import annotations

import argparse
import datetime as dt
import fnmatch
import hashlib
import json
import os
from pathlib import Path
import re
import sqlite3
import subprocess
import sys
from typing import Any


VALID_STATUSES = {
    "proposed",
    "active",
    "superseded",
    "expired",
    "rejected",
    "archived",
}
VALID_KINDS = {"invariant", "decision", "gotcha", "failure", "pattern", "command"}
KIND_DIRS = {
    "invariant": "invariants",
    "decision": "decisions",
    "gotcha": "gotchas",
    "failure": "failures",
    "pattern": "patterns",
    "command": "commands",
}
LINK_FIELDS = [
    "supersedes",
    "superseded_by",
    "related",
    "conflicts_with",
    "exception_of",
]
LIST_FIELDS = {"paths", "tags", "evidence"}
REQUIRED_FIELDS = [
    "id",
    "kind",
    "status",
    "truth_key",
    "title",
    "paths",
    "tags",
    "source_ticket",
    "created",
    "links",
]
CONFIG_DEFAULTS = {
    "memory_dir": "memory",
    "memory_index_backend": "sqlite",
    "memory_cache_dir": ".palari/cache",
    "memory_packet_limit": "5",
    "memory_related_limit": "2",
    "memory_active_only_default": "true",
    "tickets_open_dir": "tickets/open",
    "tickets_closed_dir": "tickets/closed",
}


class PalariMemoryError(Exception):
    pass


def today() -> dt.date:
    return dt.datetime.now(dt.UTC).date()


def now_iso() -> str:
    return dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def die(message: str, code: int = 2) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(code)


def warn(message: str) -> None:
    print(f"warning: {message}", file=sys.stderr)


def rel_path(root: Path, path: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def strip_quotes(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def parse_inline_list(raw: str) -> list[str]:
    value = raw.strip()
    if not value or value == "[]":
        return []
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [strip_quotes(part.strip()) for part in inner.split(",") if part.strip()]
    return [strip_quotes(value)]


def parse_config(root: Path) -> dict[str, str]:
    config = dict(CONFIG_DEFAULTS)
    path = root / "palari.config.yaml"
    if not path.exists():
        return config
    in_list = False
    with path.open("r", encoding="utf-8") as handle:
        for raw in handle:
            line = raw.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            if line.startswith(" ") or line.startswith("\t"):
                continue
            if ":" not in line:
                continue
            key, value = line.split(":", 1)
            key = key.strip()
            value = strip_quotes(value.strip())
            if not key:
                continue
            if value == "":
                in_list = True
                continue
            in_list = False
            if key in CONFIG_DEFAULTS:
                config[key] = value
    _ = in_list
    return config


def config_int(config: dict[str, str], key: str, default: int) -> int:
    try:
        return int(config.get(key, str(default)))
    except ValueError:
        return default


def split_frontmatter(text: str) -> tuple[list[str], str, bool]:
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return [], text, False
    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            body = "\n".join(lines[index + 1 :])
            if text.endswith("\n"):
                body += "\n"
            return lines[1:index], body, True
    return [], text, False


def empty_links() -> dict[str, list[str]]:
    return {field: [] for field in LINK_FIELDS}


def parse_frontmatter(lines: list[str]) -> dict[str, Any]:
    data: dict[str, Any] = {"links": empty_links()}
    current: str | None = None
    nested: str | None = None
    for raw in lines:
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        stripped = raw.strip()
        if indent == 0 and ":" in stripped:
            key, value = stripped.split(":", 1)
            key = key.strip()
            value = value.strip()
            current = key
            nested = None
            if key == "links":
                data["links"] = empty_links()
            elif key in LIST_FIELDS:
                data[key] = parse_inline_list(value)
            elif key in LINK_FIELDS:
                data.setdefault("links", empty_links())[key] = parse_inline_list(value)
                current = "links"
                nested = key
            else:
                data[key] = strip_quotes(value)
            continue
        if indent >= 2 and current == "links":
            if ":" in stripped and not stripped.startswith("- "):
                key, value = stripped.split(":", 1)
                key = key.strip()
                if key in LINK_FIELDS:
                    data.setdefault("links", empty_links())[key] = parse_inline_list(value)
                    nested = key
                continue
            if stripped.startswith("- ") and nested:
                item = strip_quotes(stripped[2:].strip())
                if item:
                    data.setdefault("links", empty_links()).setdefault(nested, []).append(item)
            continue
        if indent >= 2 and current and stripped.startswith("- "):
            item = strip_quotes(stripped[2:].strip())
            if not item:
                continue
            existing = data.get(current)
            if not isinstance(existing, list):
                data[current] = []
            data[current].append(item)
    for field in LIST_FIELDS:
        value = data.get(field, [])
        if isinstance(value, str):
            data[field] = [value] if value else []
    links = data.get("links")
    if not isinstance(links, dict):
        links = empty_links()
    for field in LINK_FIELDS:
        value = links.get(field, [])
        if isinstance(value, str):
            links[field] = [value] if value else []
        elif not isinstance(value, list):
            links[field] = []
    data["links"] = links
    return data


def extract_summary(body: str) -> str:
    lines = body.splitlines()
    for index, line in enumerate(lines):
        if re.match(r"^##\s+Current Truth\s*$", line.strip(), re.IGNORECASE):
            collected: list[str] = []
            for candidate in lines[index + 1 :]:
                if candidate.startswith("## "):
                    break
                if candidate.strip():
                    collected.append(candidate.strip())
                elif collected:
                    break
            if collected:
                return " ".join(collected).strip()
    paragraph: list[str] = []
    past_title = False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("# "):
            past_title = True
            continue
        if not stripped:
            if paragraph:
                break
            continue
        if not past_title and stripped.startswith("---"):
            continue
        paragraph.append(stripped)
    return " ".join(paragraph).strip()


def memory_source_files(root: Path, config: dict[str, str]) -> list[Path]:
    memory_dir = root / config["memory_dir"]
    if not memory_dir.exists():
        return []
    files = []
    for path in memory_dir.rglob("*.md"):
        if path.name == "README.md":
            continue
        files.append(path)
    return sorted(files)


def read_memory(path: Path, root: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    fm_lines, body, has_fm = split_frontmatter(text)
    data = parse_frontmatter(fm_lines) if has_fm else {"links": empty_links()}
    data["file"] = rel_path(root, path)
    data["_path"] = path
    data["body"] = body
    data["has_frontmatter"] = has_fm
    data["summary"] = extract_summary(body)
    data["sha"] = sha256_file(path)
    return data


def load_memories(root: Path, config: dict[str, str]) -> list[dict[str, Any]]:
    return [read_memory(path, root) for path in memory_source_files(root, config)]


def memory_to_index(memory: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": memory.get("id", ""),
        "file": memory.get("file", ""),
        "kind": memory.get("kind", ""),
        "status": memory.get("status", ""),
        "truth_key": memory.get("truth_key", ""),
        "title": memory.get("title", ""),
        "summary": memory.get("summary", ""),
        "source_ticket": memory.get("source_ticket", ""),
        "source_report": memory.get("source_report", ""),
        "created": memory.get("created", ""),
        "review_after": memory.get("review_after", ""),
        "expires_at": memory.get("expires_at", ""),
        "paths": list(memory.get("paths", [])),
        "tags": list(memory.get("tags", [])),
        "evidence": list(memory.get("evidence", [])),
        "links": {field: list(memory.get("links", {}).get(field, [])) for field in LINK_FIELDS},
        "body": memory.get("body", ""),
        "sha": memory.get("sha", ""),
    }


def source_hash(memories: list[dict[str, Any]]) -> str:
    digest = hashlib.sha256()
    for memory in sorted(memories, key=lambda item: item.get("file", "")):
        digest.update(memory.get("file", "").encode("utf-8"))
        digest.update(b"\0")
        digest.update(memory.get("sha", "").encode("utf-8"))
        digest.update(b"\0")
    return digest.hexdigest()


def parse_date(value: str | None) -> dt.date | None:
    if not value:
        return None
    try:
        return dt.date.fromisoformat(value[:10])
    except ValueError:
        return None


def is_past_date(value: str | None) -> bool:
    parsed = parse_date(value)
    return bool(parsed and parsed < today())


def is_expired(memory: dict[str, Any]) -> bool:
    if memory.get("status") == "expired":
        return True
    return is_past_date(memory.get("expires_at"))


def has_superseded_by(memory: dict[str, Any]) -> bool:
    return bool(memory.get("links", {}).get("superseded_by"))


def is_packet_truth(memory: dict[str, Any]) -> bool:
    return (
        memory.get("status") == "active"
        and not is_expired(memory)
        and not has_superseded_by(memory)
    )


def path_matches(path: str, pattern: str) -> bool:
    clean_path = path.removeprefix("./")
    clean_pattern = pattern.removeprefix("./")
    return fnmatch.fnmatchcase(clean_path, clean_pattern)


def pattern_base(pattern: str) -> str:
    clean = pattern.removeprefix("./")
    wildcard_positions = [pos for token in ["**", "*", "?", "["] if (pos := clean.find(token)) >= 0]
    if wildcard_positions:
        clean = clean[: min(wildcard_positions)]
    clean = clean.rstrip("/")
    if clean.endswith("/"):
        clean = clean[:-1]
    return clean


def patterns_overlap(left: str, right: str) -> bool:
    left = left.removeprefix("./")
    right = right.removeprefix("./")
    if left == right:
        return True
    left_base = pattern_base(left)
    right_base = pattern_base(right)
    if not left_base or not right_base:
        return False
    if left_base == right_base:
        return True
    if left_base.startswith(right_base + "/") or right_base.startswith(left_base + "/"):
        return True
    return path_matches(left_base, right) or path_matches(right_base, left)


def relationship_allows_overlap(left: dict[str, Any], right: dict[str, Any]) -> bool:
    left_id = left.get("id", "")
    right_id = right.get("id", "")
    left_links = left.get("links", {})
    right_links = right.get("links", {})
    if right_id in left_links.get("exception_of", []):
        return True
    if left_id in right_links.get("exception_of", []):
        return True
    for field in ("supersedes", "superseded_by"):
        if right_id in left_links.get(field, []):
            return True
        if left_id in right_links.get(field, []):
            return True
    return False


def valid_path_glob(pattern: str) -> bool:
    if not pattern or "\0" in pattern or pattern.startswith("/"):
        return False
    parts = Path(pattern).parts
    return ".." not in parts


def ticket_id_from_file(path: Path) -> str:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return ""
    fm_lines, _, has_fm = split_frontmatter(text)
    if has_fm:
        data = parse_frontmatter(fm_lines)
        if data.get("id"):
            return str(data["id"])
    return path.stem.split("-")[0]


def ticket_ids(root: Path, config: dict[str, str]) -> set[str]:
    ids: set[str] = set()
    for key in ("tickets_open_dir", "tickets_closed_dir"):
        directory = root / config[key]
        if not directory.exists():
            continue
        for path in directory.glob("*.md"):
            if path.name == "README.md":
                continue
            ticket_id = ticket_id_from_file(path)
            if ticket_id:
                ids.add(ticket_id)
    return ids


def lint_memories(root: Path, config: dict[str, str]) -> tuple[list[str], list[str], list[dict[str, Any]]]:
    memory_dir = root / config["memory_dir"]
    if not memory_dir.exists():
        return [], [], []
    memories = load_memories(root, config)
    errors: list[str] = []
    warnings: list[str] = []
    seen_ids: dict[str, str] = {}
    ids = {memory.get("id", "") for memory in memories if memory.get("id")}
    local_ticket_ids = ticket_ids(root, config)

    for memory in memories:
        label = memory.get("file", "memory")
        if not memory.get("has_frontmatter"):
            errors.append(f"{label}: missing YAML frontmatter")
            continue
        for field in REQUIRED_FIELDS:
            value = memory.get(field)
            if field == "links":
                if not isinstance(value, dict):
                    errors.append(f"{label}: missing required field: links")
                continue
            if isinstance(value, list):
                if not value:
                    errors.append(f"{label}: missing required field: {field}")
            elif not value:
                errors.append(f"{label}: missing required field: {field}")
        memory_id = memory.get("id", "")
        if memory_id:
            if memory_id in seen_ids:
                errors.append(f"{label}: duplicate id {memory_id} also used by {seen_ids[memory_id]}")
            seen_ids[memory_id] = label
        kind = memory.get("kind", "")
        if kind and kind not in VALID_KINDS:
            errors.append(f"{label}: unknown kind: {kind}")
        status = memory.get("status", "")
        if status and status not in VALID_STATUSES:
            errors.append(f"{label}: unknown status: {status}")
        for pattern in memory.get("paths", []):
            if not valid_path_glob(pattern):
                errors.append(f"{label}: invalid path glob: {pattern}")
        for field in LINK_FIELDS:
            for target in memory.get("links", {}).get(field, []):
                if target and target not in ids:
                    errors.append(f"{label}: broken {field} link: {target}")
        if status == "active" and is_past_date(memory.get("expires_at")):
            errors.append(f"{label}: active memory is past expires_at")
        if status == "active" and has_superseded_by(memory):
            errors.append(f"{label}: active memory has superseded_by")
        if status == "superseded" and not has_superseded_by(memory):
            errors.append(f"{label}: superseded memory without superseded_by")
        source_ticket = memory.get("source_ticket", "")
        if local_ticket_ids and source_ticket and source_ticket not in local_ticket_ids:
            errors.append(f"{label}: source_ticket does not exist locally: {source_ticket}")
        source_report = memory.get("source_report", "")
        if source_report and not (root / source_report).exists():
            errors.append(f"{label}: source_report does not exist: {source_report}")
        review_after = parse_date(memory.get("review_after"))
        if review_after and review_after < today():
            warnings.append(f"{label}: review_after has passed")
        created = parse_date(memory.get("created"))
        if status == "proposed" and created and (today() - created).days > 30:
            warnings.append(f"{label}: proposed memory is older than 30 days")
        if len(memory.get("tags", [])) > 8:
            warnings.append(f"{label}: memory has too many tags")
        if not memory.get("evidence"):
            warnings.append(f"{label}: memory has no evidence list")
        if "## Current Truth" not in memory.get("body", ""):
            warnings.append(f"{label}: memory body has no Current Truth section")

    active = [memory for memory in memories if is_packet_truth(memory)]
    for index, left in enumerate(active):
        for right in active[index + 1 :]:
            if left.get("truth_key") != right.get("truth_key"):
                continue
            overlapping = any(
                patterns_overlap(left_path, right_path)
                for left_path in left.get("paths", [])
                for right_path in right.get("paths", [])
            )
            if overlapping and not relationship_allows_overlap(left, right):
                errors.append(
                    f"{left.get('file')}: active truth_key {left.get('truth_key')} overlaps "
                    f"{right.get('file')} without exception or supersede relationship"
                )
    return errors, warnings, memories


def print_lint(root: Path, config: dict[str, str], json_output: bool) -> int:
    memory_dir = root / config["memory_dir"]
    if not memory_dir.exists():
        payload = {"ok": True, "errors": [], "warnings": [], "total": 0, "memory_dir": config["memory_dir"]}
        if json_output:
            print(json.dumps(payload, indent=2))
        else:
            print("memory-lint: ok (no memory directory)")
        return 0
    errors, warnings, memories = lint_memories(root, config)
    payload = {
        "ok": not errors,
        "errors": errors,
        "warnings": warnings,
        "total": len(memories),
        "memory_dir": config["memory_dir"],
    }
    if json_output:
        print(json.dumps(payload, indent=2))
    else:
        for message in errors:
            print(f"memory-lint: error: {message}", file=sys.stderr)
        for message in warnings:
            print(f"memory-lint: warning: {message}", file=sys.stderr)
        if errors:
            print(f"memory-lint: failed ({len(errors)} error(s), {len(warnings)} warning(s))", file=sys.stderr)
        else:
            print(f"memory-lint: ok ({len(memories)} memories, {len(warnings)} warning(s))")
    return 1 if errors else 0


def cache_dir(root: Path, config: dict[str, str]) -> Path:
    return root / config["memory_cache_dir"]


def json_index_path(root: Path, config: dict[str, str]) -> Path:
    return cache_dir(root, config) / "memory-index.json"


def sqlite_index_path(root: Path, config: dict[str, str]) -> Path:
    return cache_dir(root, config) / "memory.sqlite"


def has_fts5(conn: sqlite3.Connection) -> bool:
    try:
        conn.execute("CREATE VIRTUAL TABLE temp.test_fts USING fts5(x)")
        return True
    except sqlite3.OperationalError:
        return False


def write_json_atomic(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(tmp, path)


def build_json_index(root: Path, config: dict[str, str], memories: list[dict[str, Any]]) -> dict[str, Any]:
    records = [memory_to_index(memory) for memory in memories]
    return {
        "schema": 1,
        "generated_at": now_iso(),
        "memory_dir": config["memory_dir"],
        "source_hash": source_hash(memories),
        "memories": records,
    }


def create_sqlite_schema(conn: sqlite3.Connection, with_fts: bool) -> None:
    conn.executescript(
        """
        CREATE TABLE memory (
          id TEXT PRIMARY KEY,
          file TEXT NOT NULL,
          kind TEXT NOT NULL,
          status TEXT NOT NULL,
          truth_key TEXT NOT NULL,
          title TEXT NOT NULL,
          summary TEXT NOT NULL,
          source_ticket TEXT,
          source_report TEXT,
          created TEXT,
          review_after TEXT,
          expires_at TEXT,
          body TEXT NOT NULL,
          sha TEXT NOT NULL
        );

        CREATE TABLE memory_path (
          memory_id TEXT NOT NULL,
          path TEXT NOT NULL
        );
        CREATE INDEX idx_memory_path_path ON memory_path(path);

        CREATE TABLE memory_tag (
          memory_id TEXT NOT NULL,
          tag TEXT NOT NULL
        );
        CREATE INDEX idx_memory_tag_tag ON memory_tag(tag);

        CREATE TABLE memory_edge (
          from_id TEXT NOT NULL,
          to_id TEXT NOT NULL,
          edge_type TEXT NOT NULL
        );
        CREATE INDEX idx_memory_edge_from ON memory_edge(from_id);
        CREATE INDEX idx_memory_edge_to ON memory_edge(to_id);

        CREATE TABLE meta (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );
        """
    )
    if with_fts:
        conn.execute(
            """
            CREATE VIRTUAL TABLE memory_fts USING fts5(
              id UNINDEXED,
              title,
              summary,
              body,
              tags,
              paths,
              truth_key,
              tokenize = 'unicode61'
            )
            """
        )


def write_sqlite_index(root: Path, config: dict[str, str], payload: dict[str, Any]) -> bool:
    path = sqlite_index_path(root, config)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    if tmp.exists():
        tmp.unlink()
    conn = sqlite3.connect(tmp)
    try:
        fts = has_fts5(conn)
        if not fts:
            warn("SQLite FTS5 is unavailable; using JSON memory index fallback")
            conn.close()
            tmp.unlink(missing_ok=True)
            return False
        create_sqlite_schema(conn, with_fts=True)
        conn.execute("INSERT INTO meta(key, value) VALUES (?, ?)", ("schema", "1"))
        conn.execute("INSERT INTO meta(key, value) VALUES (?, ?)", ("source_hash", payload["source_hash"]))
        conn.execute("INSERT INTO meta(key, value) VALUES (?, ?)", ("generated_at", payload["generated_at"]))
        for memory in payload["memories"]:
            conn.execute(
                """
                INSERT INTO memory(
                  id, file, kind, status, truth_key, title, summary, source_ticket,
                  source_report, created, review_after, expires_at, body, sha
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    memory["id"],
                    memory["file"],
                    memory["kind"],
                    memory["status"],
                    memory["truth_key"],
                    memory["title"],
                    memory["summary"],
                    memory.get("source_ticket", ""),
                    memory.get("source_report", ""),
                    memory.get("created", ""),
                    memory.get("review_after", ""),
                    memory.get("expires_at", ""),
                    memory.get("body", ""),
                    memory.get("sha", ""),
                ),
            )
            for path_item in memory.get("paths", []):
                conn.execute("INSERT INTO memory_path(memory_id, path) VALUES (?, ?)", (memory["id"], path_item))
            for tag in memory.get("tags", []):
                conn.execute("INSERT INTO memory_tag(memory_id, tag) VALUES (?, ?)", (memory["id"], tag))
            for edge_type, targets in memory.get("links", {}).items():
                for target in targets:
                    conn.execute(
                        "INSERT INTO memory_edge(from_id, to_id, edge_type) VALUES (?, ?, ?)",
                        (memory["id"], target, edge_type),
                    )
            conn.execute(
                """
                INSERT INTO memory_fts(id, title, summary, body, tags, paths, truth_key)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    memory["id"],
                    memory["title"],
                    memory["summary"],
                    memory.get("body", ""),
                    " ".join(memory.get("tags", [])),
                    " ".join(memory.get("paths", [])),
                    memory["truth_key"],
                ),
            )
        conn.commit()
    finally:
        conn.close()
    os.replace(tmp, path)
    return True


def cmd_index(root: Path, config: dict[str, str], args: argparse.Namespace) -> int:
    backend = config.get("memory_index_backend", "sqlite")
    if args.sqlite:
        backend = "sqlite"
    if args.json:
        backend = "json"
    memories = load_memories(root, config)
    payload = build_json_index(root, config, memories)
    if backend != "none":
        write_json_atomic(json_index_path(root, config), payload)
    sqlite_written = False
    if backend == "sqlite":
        sqlite_written = write_sqlite_index(root, config, payload)
    print(
        "memory index: ok "
        f"({len(memories)} memories, json={'yes' if backend != 'none' else 'no'}, "
        f"sqlite={'yes' if sqlite_written else 'no'})"
    )
    return 0


def current_source_hash(root: Path, config: dict[str, str]) -> str:
    return source_hash(load_memories(root, config))


def load_index_payload(root: Path, config: dict[str, str]) -> dict[str, Any]:
    path = json_index_path(root, config)
    current = current_source_hash(root, config)
    if path.exists():
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
            if payload.get("source_hash") == current:
                return payload
        except json.JSONDecodeError:
            pass
    memories = load_memories(root, config)
    payload = build_json_index(root, config, memories)
    if config.get("memory_index_backend", "sqlite") != "none":
        write_json_atomic(path, payload)
        if config.get("memory_index_backend", "sqlite") == "sqlite":
            write_sqlite_index(root, config, payload)
    return payload


def sqlite_source_hash(path: Path) -> str | None:
    if not path.exists():
        return None
    try:
        conn = sqlite3.connect(path)
        try:
            row = conn.execute("SELECT value FROM meta WHERE key = 'source_hash'").fetchone()
            return row[0] if row else None
        finally:
            conn.close()
    except sqlite3.Error:
        return None


def sqlite_fts_ids(root: Path, config: dict[str, str], text: str) -> set[str]:
    path = sqlite_index_path(root, config)
    if sqlite_source_hash(path) != current_source_hash(root, config):
        return set()
    try:
        conn = sqlite3.connect(path)
        try:
            query = " OR ".join(token for token in re.findall(r"[A-Za-z0-9_./-]+", text) if token)
            if not query:
                return set()
            rows = conn.execute(
                "SELECT id FROM memory_fts WHERE memory_fts MATCH ? LIMIT 50",
                (query,),
            ).fetchall()
            return {row[0] for row in rows}
        finally:
            conn.close()
    except sqlite3.Error:
        return set()


def normalized_words(text: str) -> set[str]:
    return {word.lower() for word in re.findall(r"[A-Za-z0-9][A-Za-z0-9_-]*", text)}


def memory_search_blob(memory: dict[str, Any]) -> str:
    return " ".join(
        [
            memory.get("id", ""),
            memory.get("title", ""),
            memory.get("truth_key", ""),
            memory.get("summary", ""),
            " ".join(memory.get("tags", [])),
            " ".join(memory.get("paths", [])),
            memory.get("body", ""),
        ]
    ).lower()


def rank_query(
    root: Path,
    config: dict[str, str],
    memories: list[dict[str, Any]],
    *,
    text: str = "",
    path: str = "",
    tag: str = "",
    truth_key: str = "",
    include_inactive: bool = False,
) -> list[dict[str, Any]]:
    fts_ids = sqlite_fts_ids(root, config, text) if text else set()
    terms = normalized_words(text)
    results: list[dict[str, Any]] = []
    for memory in memories:
        if not include_inactive and not is_packet_truth(memory):
            continue
        score = 0
        reasons: list[str] = []
        if path:
            matches = [pattern for pattern in memory.get("paths", []) if path_matches(path, pattern)]
            if not matches:
                continue
            longest = max(len(match) for match in matches)
            score += 1000 + longest
            reasons.append(f"path:{matches[0]}")
        if tag:
            if tag not in memory.get("tags", []):
                continue
            score += 300
            reasons.append(f"tag:{tag}")
        if truth_key:
            if truth_key != memory.get("truth_key"):
                continue
            score += 500
            reasons.append(f"truth_key:{truth_key}")
        if text:
            blob = memory_search_blob(memory)
            term_hits = sum(1 for term in terms if term in blob)
            if memory.get("id") in fts_ids:
                term_hits += 1
                score += 200
                reasons.append("fts")
            if term_hits == 0:
                continue
            score += 200 + term_hits
            reasons.append("text")
        if not any([text, path, tag, truth_key]):
            score += 1
        record = dict(memory)
        record["score"] = score
        record["match_reasons"] = reasons
        results.append(record)
    results.sort(key=lambda item: (-int(item.get("score", 0)), item.get("id", "")))
    return results


def print_query_results(results: list[dict[str, Any]], json_output: bool) -> int:
    if json_output:
        print(json.dumps({"memories": [memory_to_public(memory) for memory in results[:20]]}, indent=2))
        return 0
    if not results:
        print("memory query: no matches")
        return 0
    for memory in results[:20]:
        print(
            f"{memory.get('id')} {memory.get('status')} {memory.get('kind')} "
            f"{memory.get('truth_key')}: {memory.get('title')}"
        )
        if memory.get("summary"):
            print(f"  {memory.get('summary')}")
        if memory.get("paths"):
            print(f"  paths: {', '.join(memory.get('paths', []))}")
        print(f"  file: {memory.get('file')}")
    return 0


def memory_to_public(memory: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": memory.get("id", ""),
        "kind": memory.get("kind", ""),
        "status": memory.get("status", ""),
        "truth_key": memory.get("truth_key", ""),
        "title": memory.get("title", ""),
        "paths": list(memory.get("paths", [])),
        "tags": list(memory.get("tags", [])),
        "summary": memory.get("summary", ""),
        "source_ticket": memory.get("source_ticket", ""),
        "source_report": memory.get("source_report", ""),
        "file": memory.get("file", ""),
        "score": memory.get("score", 0),
        "match_reasons": list(memory.get("match_reasons", [])),
    }


def cmd_query(root: Path, config: dict[str, str], args: argparse.Namespace) -> int:
    payload = load_index_payload(root, config)
    memories = payload.get("memories", [])
    active_only_default = config.get("memory_active_only_default", "true").lower() != "false"
    results = rank_query(
        root,
        config,
        memories,
        text=args.text or "",
        path=args.path or "",
        tag=args.tag or "",
        truth_key=args.truth_key or "",
        include_inactive=args.include_inactive or not active_only_default,
    )
    return print_query_results(results, args.json)


def find_ticket(root: Path, config: dict[str, str], ticket: str) -> Path | None:
    for key in ("tickets_open_dir", "tickets_closed_dir"):
        directory = root / config[key]
        if not directory.exists():
            continue
        for path in sorted(directory.glob("*.md")):
            if path.name == "README.md":
                continue
            ticket_id = ticket_id_from_file(path)
            if ticket_id == ticket or path.stem == ticket or path.name == ticket:
                return path
    return None


def read_ticket_context(root: Path, config: dict[str, str], ticket: str) -> dict[str, Any]:
    path = find_ticket(root, config, ticket)
    if not path:
        raise PalariMemoryError(f"ticket not found: {ticket}")
    text = path.read_text(encoding="utf-8")
    fm_lines, body, has_fm = split_frontmatter(text)
    data = parse_frontmatter(fm_lines) if has_fm else {}
    data["body"] = body
    data["file"] = rel_path(root, path)
    data["id"] = data.get("id") or ticket
    return data


def changed_files(root: Path) -> list[str]:
    git = os.environ.get("GIT", "git")
    commands = [
        [git, "-C", str(root), "diff", "--name-only", "--relative", "--", "."],
        [git, "-C", str(root), "diff", "--name-only", "--cached", "--relative", "--", "."],
        [git, "-C", str(root), "ls-files", "--others", "--exclude-standard", "--", "."],
    ]
    paths: set[str] = set()
    for command in commands:
        try:
            result = subprocess.run(command, check=False, capture_output=True, text=True)
        except OSError:
            continue
        for line in result.stdout.splitlines():
            if line.strip():
                paths.add(line.strip())
    return sorted(paths)


def score_context_memory(
    memory: dict[str, Any],
    ticket: dict[str, Any],
    changed: list[str],
    text_terms: set[str],
) -> tuple[int, list[str]]:
    score = 0
    reasons: list[str] = []
    for changed_path in changed:
        matches = [pattern for pattern in memory.get("paths", []) if path_matches(changed_path, pattern)]
        if matches:
            score += 1000
            reasons.append(f"path:{matches[0]}")
            break
    for allowed in ticket.get("allowed_paths", []):
        matches = [pattern for pattern in memory.get("paths", []) if patterns_overlap(allowed, pattern)]
        if matches:
            score += 700
            reasons.append(f"allowed_path:{matches[0]}")
            break
    tag_hits = text_terms.intersection({tag.lower() for tag in memory.get("tags", [])})
    if tag_hits:
        score += 300
        reasons.append(f"tag:{sorted(tag_hits)[0]}")
    blob = memory_search_blob(memory)
    if text_terms and any(term in blob for term in text_terms):
        score += 200
        reasons.append("ticket-text")
    if is_past_date(memory.get("review_after")):
        score -= 100
        reasons.append("review_after-passed")
    return score, reasons


def related_active_memories(
    memories_by_id: dict[str, dict[str, Any]],
    selected: list[dict[str, Any]],
    related_limit: int,
) -> list[dict[str, Any]]:
    related: list[dict[str, Any]] = []
    selected_ids = {memory.get("id") for memory in selected}
    for memory in selected:
        for target in memory.get("links", {}).get("related", []):
            candidate = memories_by_id.get(target)
            if not candidate or candidate.get("id") in selected_ids or not is_packet_truth(candidate):
                continue
            record = dict(candidate)
            record["score"] = 100
            record["match_reasons"] = [f"related:{memory.get('id')}"]
            related.append(record)
            selected_ids.add(candidate.get("id"))
            if len(related) >= related_limit:
                return related
    return related


def active_contradiction_warnings(memories: list[dict[str, Any]]) -> list[str]:
    warnings: list[str] = []
    active = [memory for memory in memories if is_packet_truth(memory)]
    for index, left in enumerate(active):
        for right in active[index + 1 :]:
            if left.get("truth_key") != right.get("truth_key"):
                continue
            if any(
                patterns_overlap(left_path, right_path)
                for left_path in left.get("paths", [])
                for right_path in right.get("paths", [])
            ) and not relationship_allows_overlap(left, right):
                warnings.append(
                    f"unresolved active memory contradiction: {left.get('id')} and {right.get('id')} "
                    f"share {left.get('truth_key')}"
                )
    return warnings


def context_payload(
    root: Path,
    config: dict[str, str],
    ticket_id: str,
    role: str,
    limit: int,
) -> dict[str, Any]:
    ticket = read_ticket_context(root, config, ticket_id)
    payload = load_index_payload(root, config)
    memories = payload.get("memories", [])
    text_terms = normalized_words(
        " ".join(
            [
                str(ticket.get("id", "")),
                str(ticket.get("title", "")),
                str(ticket.get("stream", "")),
                ticket.get("body", "")[:1000],
            ]
        )
    )
    changed = changed_files(root)
    direct: list[dict[str, Any]] = []
    for memory in memories:
        if not is_packet_truth(memory):
            continue
        score, reasons = score_context_memory(memory, ticket, changed, text_terms)
        if score <= 0:
            continue
        record = dict(memory)
        record["score"] = score
        record["match_reasons"] = reasons
        direct.append(record)
    direct.sort(key=lambda item: (-int(item.get("score", 0)), item.get("id", "")))
    direct = direct[:limit]
    memories_by_id = {memory.get("id", ""): memory for memory in memories if memory.get("id")}
    related = related_active_memories(memories_by_id, direct, config_int(config, "memory_related_limit", 2))
    selected = direct + related
    return {
        "ticket": ticket.get("id", ticket_id),
        "role": role,
        "memories": [memory_to_public(memory) for memory in selected],
        "warnings": active_contradiction_warnings(memories),
        "memory_index_hash": payload.get("source_hash", ""),
    }


def write_context_lock(root: Path, payload: dict[str, Any], index_payload: dict[str, Any]) -> None:
    ticket = payload["ticket"]
    directory = root / ".palari" / "packets" / ticket
    directory.mkdir(parents=True, exist_ok=True)
    memories_by_id = {memory.get("id"): memory for memory in index_payload.get("memories", [])}
    lock = {
        "ticket": ticket,
        "role": payload["role"],
        "generated_at": now_iso(),
        "memory_index_hash": payload.get("memory_index_hash", ""),
        "memories": [
            {
                "id": memory["id"],
                "file": memory["file"],
                "sha": memories_by_id.get(memory["id"], {}).get("sha", ""),
            }
            for memory in payload.get("memories", [])
        ],
    }
    write_json_atomic(directory / "memory-context.json", lock)


def print_context(payload: dict[str, Any], role: str) -> None:
    print("Relevant Memory:")
    if role == "reviewer":
        print("  Reviewer memory rule:")
        print("  Check whether the implementation violated included memories.")
        print("  Check whether this ticket supersedes, narrows, or creates memory.")
        print("  Recommend memory updates, but do not silently promote them.")
    else:
        print("  Memory rule:")
        print("  The orchestrator selected relevant active repo memories for this ticket.")
        print("  Use the memory included here, plus the ticket and scoped files.")
        print("  Do not browse the full memory directory unless blocked.")
        print("  If memory is missing, stale, or contradictory, stop and report a handoff.")
    if not payload.get("memories"):
        print("  - none selected")
    for memory in payload.get("memories", []):
        print(f"  - {memory['id']} {memory['kind']} {memory['truth_key']}")
        print(f"    Title: {memory['title']}")
        print(f"    Applies: {', '.join(memory.get('paths', [])) or 'unspecified'}")
        print(f"    Truth: {memory.get('summary') or 'See source memory file.'}")
        print(f"    Source: {memory.get('source_ticket') or 'unknown'}")
    for warning_message in payload.get("warnings", []):
        print(f"  Warning: {warning_message}")


def cmd_context(root: Path, config: dict[str, str], args: argparse.Namespace) -> int:
    limit = args.limit or config_int(config, "memory_packet_limit", 5)
    role = args.role or "specialist"
    try:
        payload = context_payload(root, config, args.ticket, role, limit)
    except PalariMemoryError as exc:
        die(str(exc))
    if args.write_lock:
        index_payload = load_index_payload(root, config)
        write_context_lock(root, payload, index_payload)
    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        print_context(payload, role)
    return 0


def next_memory_id(memories: list[dict[str, Any]]) -> str:
    max_seen = 0
    for memory in memories:
        match = re.match(r"^MEM-(\d{4,})$", str(memory.get("id", "")))
        if match:
            max_seen = max(max_seen, int(match.group(1)))
    return f"MEM-{max_seen + 1:04d}"


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return re.sub(r"-+", "-", slug) or "memory"


def yaml_list(name: str, values: list[str], indent: str = "") -> list[str]:
    lines = [f"{indent}{name}:"]
    if values:
        lines.extend(f"{indent}  - {value}" for value in values)
    return lines


def render_frontmatter(memory: dict[str, Any]) -> str:
    lines = [
        "---",
        f"id: {memory.get('id', '')}",
        f"kind: {memory.get('kind', '')}",
        f"status: {memory.get('status', '')}",
        f"truth_key: {memory.get('truth_key', '')}",
        f"title: {memory.get('title', '')}",
    ]
    lines.extend(yaml_list("paths", list(memory.get("paths", []))))
    lines.extend(yaml_list("tags", list(memory.get("tags", []))))
    lines.append(f"source_ticket: {memory.get('source_ticket', '')}")
    lines.append(f"source_report: {memory.get('source_report', '')}")
    lines.extend(yaml_list("evidence", list(memory.get("evidence", []))))
    lines.append(f"created: {memory.get('created', '')}")
    lines.append(f"review_after: {memory.get('review_after', '')}")
    lines.append(f"expires_at: {memory.get('expires_at', '')}")
    lines.append("links:")
    links = memory.get("links", empty_links())
    for field in LINK_FIELDS:
        lines.extend(yaml_list(field, list(links.get(field, [])), indent="  "))
    lines.append("---")
    return "\n".join(lines) + "\n"


def write_memory(path: Path, memory: dict[str, Any], body: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(render_frontmatter(memory) + "\n" + body.lstrip(), encoding="utf-8")


def generated_body(title: str, body: str | None) -> str:
    if body:
        text = body.strip()
        if text.startswith("# "):
            return text + "\n"
        return f"# {title}\n\n{text}\n"
    return (
        f"# {title}\n\n"
        "## Current Truth\n\n"
        "TODO: State the durable repo truth in one or two concrete paragraphs.\n\n"
        "## Why\n\n"
        "TODO: Explain why this memory matters.\n\n"
        "## Checks\n\n"
        "- TODO\n\n"
        "## Violation Examples\n\n"
        "- TODO\n"
    )


def cmd_add(root: Path, config: dict[str, str], args: argparse.Namespace) -> int:
    if args.kind not in VALID_KINDS:
        die(f"unknown memory kind: {args.kind}")
    if args.status not in VALID_STATUSES:
        die(f"unknown memory status: {args.status}")
    if not args.truth_key:
        die("memory add requires --truth-key")
    if not args.path:
        die("memory add requires at least one --path")
    if not args.source_ticket:
        die("memory add requires --source-ticket")
    memories = load_memories(root, config)
    memory_id = next_memory_id(memories)
    memory_dir = root / config["memory_dir"] / KIND_DIRS[args.kind]
    path = memory_dir / f"{memory_id}-{slugify(args.title)}.md"
    if path.exists():
        die(f"memory file already exists: {rel_path(root, path)}")
    memory = {
        "id": memory_id,
        "kind": args.kind,
        "status": args.status,
        "truth_key": args.truth_key,
        "title": args.title,
        "paths": args.path,
        "tags": args.tag or [],
        "source_ticket": args.source_ticket,
        "source_report": args.source_report or "",
        "evidence": args.evidence or [],
        "created": today().isoformat(),
        "review_after": args.review_after or "",
        "expires_at": args.expires_at or "",
        "links": empty_links(),
    }
    write_memory(path, memory, generated_body(args.title, args.body))
    print(f"memory add: {rel_path(root, path)}")
    return 0


def find_memory_by_id(memories: list[dict[str, Any]], memory_id: str) -> dict[str, Any] | None:
    for memory in memories:
        if memory.get("id") == memory_id:
            return memory
    return None


def rewrite_existing_memory(memory: dict[str, Any]) -> None:
    path = memory.get("_path")
    if not isinstance(path, Path):
        raise PalariMemoryError(f"memory has no path: {memory.get('id')}")
    write_memory(path, memory, memory.get("body", ""))


def cmd_supersede(root: Path, config: dict[str, str], args: argparse.Namespace) -> int:
    memories = load_memories(root, config)
    old = find_memory_by_id(memories, args.memory_id)
    if not old:
        die(f"memory not found: {args.memory_id}")
    status = args.status or "active"
    if status not in {"active", "proposed"}:
        die("memory supersede status must be active or proposed")
    new_id = next_memory_id(memories)
    title = args.title or f"{old.get('title', '')} (updated)"
    paths = args.path or list(old.get("paths", []))
    tags = args.tag or list(old.get("tags", []))
    new_memory = {
        "id": new_id,
        "kind": old.get("kind", ""),
        "status": status,
        "truth_key": old.get("truth_key", ""),
        "title": title,
        "paths": paths,
        "tags": tags,
        "source_ticket": args.source_ticket or old.get("source_ticket", ""),
        "source_report": args.source_report or "",
        "evidence": list(old.get("evidence", [])),
        "created": today().isoformat(),
        "review_after": "",
        "expires_at": "",
        "links": empty_links(),
    }
    new_memory["links"]["supersedes"] = [str(old.get("id"))]
    new_path = root / config["memory_dir"] / KIND_DIRS[str(old.get("kind"))] / f"{new_id}-{slugify(title)}.md"
    old_links = old.setdefault("links", empty_links())
    old_links.setdefault("superseded_by", [])
    if new_id not in old_links["superseded_by"]:
        old_links["superseded_by"].append(new_id)
    old["status"] = "superseded"
    write_memory(new_path, new_memory, generated_body(title, args.body))
    rewrite_existing_memory(old)
    code = print_lint(root, config, json_output=False)
    if code != 0:
        return code
    print(f"memory supersede: {old.get('id')} -> {new_id}")
    return 0


def cmd_retire(root: Path, config: dict[str, str], args: argparse.Namespace) -> int:
    memories = load_memories(root, config)
    memory = find_memory_by_id(memories, args.memory_id)
    if not memory:
        die(f"memory not found: {args.memory_id}")
    memory["status"] = "archived"
    reason = args.reason or "No reason recorded."
    body = memory.get("body", "").rstrip()
    body += f"\n\n## Retirement\n\n- Retired at: {now_iso()}\n- Reason: {reason}\n"
    memory["body"] = body + "\n"
    rewrite_existing_memory(memory)
    print(f"memory retire: {args.memory_id} archived")
    return 0


def cmd_promote(root: Path, config: dict[str, str], args: argparse.Namespace) -> int:
    if not args.by:
        die("memory promote requires --by")
    memories = load_memories(root, config)
    memory = find_memory_by_id(memories, args.memory_id)
    if not memory:
        die(f"memory not found: {args.memory_id}")
    if memory.get("status") != "proposed":
        die(f"memory promote requires proposed status; current: {memory.get('status')}")
    path = memory.get("_path")
    original = path.read_text(encoding="utf-8") if isinstance(path, Path) else ""
    memory["status"] = "active"
    body = memory.get("body", "").rstrip()
    body += f"\n\n## Promotion\n\n- Promoted by: {args.by}\n- Promoted at: {now_iso()}\n"
    memory["body"] = body + "\n"
    rewrite_existing_memory(memory)
    code = print_lint(root, config, json_output=False)
    if code != 0:
        if isinstance(path, Path):
            path.write_text(original, encoding="utf-8")
        return code
    print(f"memory promote: {args.memory_id} active by {args.by}")
    return 0


def cmd_graph(root: Path, config: dict[str, str], args: argparse.Namespace) -> int:
    memories = load_memories(root, config)
    by_id = {memory.get("id"): memory for memory in memories}
    selected = memories
    if args.memory_id:
        memory = by_id.get(args.memory_id)
        if not memory:
            die(f"memory not found: {args.memory_id}")
        selected = [memory]
    if args.truth_key:
        selected = [memory for memory in memories if memory.get("truth_key") == args.truth_key]
    if not selected:
        print("memory graph: no matches")
        return 0
    grouped: dict[str, list[dict[str, Any]]] = {}
    for memory in selected:
        grouped.setdefault(memory.get("truth_key", "missing"), []).append(memory)
    for truth_key in sorted(grouped):
        print(truth_key)
        for memory in sorted(grouped[truth_key], key=lambda item: item.get("id", "")):
            print(f"  {memory.get('id')} {memory.get('status')} {memory.get('kind')} {memory.get('title')}")
            links = memory.get("links", {})
            for field in LINK_FIELDS:
                targets = links.get(field, [])
                print(f"    {field}: {', '.join(targets) if targets else 'none'}")
    return 0


def memory_summary(root: Path, config: dict[str, str]) -> dict[str, Any]:
    memory_dir = root / config["memory_dir"]
    memories = load_memories(root, config) if memory_dir.exists() else []
    status_counts = {status: 0 for status in VALID_STATUSES}
    stale_review = 0
    for memory in memories:
        status = memory.get("status", "")
        if status in status_counts:
            status_counts[status] += 1
        if is_past_date(memory.get("review_after")):
            stale_review += 1
    errors, _, _ = lint_memories(root, config) if memory_dir.exists() else ([], [], [])
    index_exists = json_index_path(root, config).exists() or sqlite_index_path(root, config).exists()
    return {
        "enabled": memory_dir.exists(),
        "dir": config["memory_dir"],
        "backend": config.get("memory_index_backend", "sqlite"),
        "total": len(memories),
        "active": status_counts["active"],
        "proposed": status_counts["proposed"],
        "stale_review": stale_review,
        "lint_ok": not errors,
        "index_exists": index_exists,
    }


def cmd_summary(root: Path, config: dict[str, str], args: argparse.Namespace) -> int:
    payload = memory_summary(root, config)
    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        print(
            "memory: "
            f"{payload['active']} active, {payload['proposed']} proposed, "
            f"{payload['stale_review']} needs review"
        )
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="palari memory")
    parser.add_argument("--root", required=True)
    subparsers = parser.add_subparsers(dest="command", required=True)

    add = subparsers.add_parser("add")
    add.add_argument("kind")
    add.add_argument("title")
    add.add_argument("--truth-key", required=True)
    add.add_argument("--path", action="append", default=[])
    add.add_argument("--tag", action="append", default=[])
    add.add_argument("--source-ticket", required=True)
    add.add_argument("--source-report")
    add.add_argument("--evidence", action="append", default=[])
    add.add_argument("--review-after")
    add.add_argument("--expires-at")
    add.add_argument("--status", default="proposed")
    add.add_argument("--body")
    add.set_defaults(func=cmd_add)

    index = subparsers.add_parser("index")
    index.add_argument("--sqlite", action="store_true")
    index.add_argument("--json", action="store_true")
    index.add_argument("--rebuild", action="store_true")
    index.set_defaults(func=cmd_index)

    query = subparsers.add_parser("query")
    query.add_argument("text", nargs="?")
    query.add_argument("--path")
    query.add_argument("--tag")
    query.add_argument("--truth-key")
    query.add_argument("--include-inactive", action="store_true")
    query.add_argument("--json", action="store_true")
    query.set_defaults(func=cmd_query)

    context = subparsers.add_parser("context")
    context.add_argument("ticket")
    context.add_argument("role_positional", nargs="?")
    context.add_argument("--role")
    context.add_argument("--limit", type=int)
    context.add_argument("--json", action="store_true")
    context.add_argument("--write-lock", action="store_true")
    context.set_defaults(func=cmd_context)

    lint = subparsers.add_parser("lint")
    lint.add_argument("--json", action="store_true")
    lint.set_defaults(func=lambda root, config, args: print_lint(root, config, args.json))

    graph = subparsers.add_parser("graph")
    graph.add_argument("memory_id", nargs="?")
    graph.add_argument("--truth-key")
    graph.set_defaults(func=cmd_graph)

    supersede = subparsers.add_parser("supersede")
    supersede.add_argument("memory_id")
    supersede.add_argument("--title")
    supersede.add_argument("--source-ticket")
    supersede.add_argument("--source-report")
    supersede.add_argument("--body")
    supersede.add_argument("--status")
    supersede.add_argument("--path", action="append")
    supersede.add_argument("--tag", action="append")
    supersede.set_defaults(func=cmd_supersede)

    retire = subparsers.add_parser("retire")
    retire.add_argument("memory_id")
    retire.add_argument("--reason")
    retire.set_defaults(func=cmd_retire)

    promote = subparsers.add_parser("promote")
    promote.add_argument("memory_id")
    promote.add_argument("--by", required=True)
    promote.set_defaults(func=cmd_promote)

    summary = subparsers.add_parser("summary")
    summary.add_argument("--json", action="store_true")
    summary.set_defaults(func=cmd_summary)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    root = Path(args.root).resolve()
    config = parse_config(root)
    if getattr(args, "role_positional", None) and not getattr(args, "role", None):
        args.role = args.role_positional
    try:
        return args.func(root, config, args)
    except PalariMemoryError as exc:
        die(str(exc))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
