"""Storage adapters. Outside the trusted core: the gate verifies whatever
evidence it is handed regardless of where it lived.

FileStore   .forgegate/attestations/<content-address>.json
GitNotes    refs/notes/forgegate, one note per commit holding a JSON list
"""
import json
import os
import subprocess

from .attest import att_id

NOTES_REF = "refs/notes/forgegate"


class FileStore:
    def __init__(self, root: str = ".forgegate"):
        self.dir = os.path.join(root, "attestations")
        os.makedirs(self.dir, exist_ok=True)

    def put(self, att: dict) -> str:
        aid = att_id(att)
        path = os.path.join(self.dir, f"{aid}.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(att, f, sort_keys=True, indent=1)
        return aid

    def all(self) -> list[dict]:
        """Load every attestation, skipping anything unreadable or non-dict.
        Skipped filenames are recorded in self.skipped so callers can warn.
        Never raises on corrupt evidence: fail closed, not loud."""
        out = []
        self.skipped: list[str] = []
        for name in sorted(os.listdir(self.dir)):
            if not name.endswith(".json"):
                continue
            path = os.path.join(self.dir, name)
            try:
                with open(path, encoding="utf-8") as f:
                    item = json.load(f)
            except (json.JSONDecodeError, OSError, UnicodeDecodeError):
                self.skipped.append(name)
                continue
            if isinstance(item, dict):
                out.append(item)
            else:
                self.skipped.append(name)
        return out

    def for_ticket(self, ticket: str) -> list[dict]:
        return [a for a in self.all() if a.get("ticket") == ticket]


class GitNotes:
    """Attach attestations to commits as git notes. Uses the repo's own
    content-addressed store; survives clones that fetch the notes ref."""

    def __init__(self, repo: str = "."):
        self.repo = repo

    def _git(self, *args: str) -> str:
        res = subprocess.run(
            ["git", "-C", self.repo, *args],
            capture_output=True, text=True, check=True,
        )
        return res.stdout.strip()

    def put(self, att: dict) -> None:
        commit = att["commit"]
        existing = self.get(commit)
        existing.append(att)
        payload = json.dumps(existing, sort_keys=True)
        self._git("notes", "--ref", NOTES_REF, "add", "-f", "-m", payload, commit)

    def get(self, commit: str) -> list[dict]:
        try:
            raw = self._git("notes", "--ref", NOTES_REF, "show", commit)
            return json.loads(raw)
        except (subprocess.CalledProcessError, json.JSONDecodeError):
            return []
