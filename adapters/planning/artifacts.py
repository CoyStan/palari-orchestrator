"""Shared parsers for Palari company OS planning artifacts."""

from __future__ import annotations

import pathlib
import re
from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class Artifact:
    path: pathlib.Path
    fields: dict[str, str]
    lists: dict[str, list[str]]


def strip_quotes(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def parse_frontmatter(path: pathlib.Path, *, require: bool = True) -> Artifact:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        if require:
            raise ValueError(f"{path}: missing frontmatter")
        return Artifact(path=path, fields={}, lists={})
    end = text.find("\n---", 4)
    if end == -1:
        if require:
            raise ValueError(f"{path}: unterminated frontmatter")
        return Artifact(path=path, fields={}, lists={})
    fields: dict[str, str] = {}
    lists: dict[str, list[str]] = {}
    current_list: str | None = None
    for raw in text[4:end].splitlines():
        if not raw.strip():
            continue
        if raw.startswith("  - ") and current_list:
            lists[current_list].append(strip_quotes(raw[4:]))
            continue
        current_list = None
        if ":" not in raw:
            continue
        key, value = raw.split(":", 1)
        key = key.strip()
        value = strip_quotes(value)
        if value == "":
            fields[key] = ""
            lists.setdefault(key, [])
            current_list = key
        else:
            fields[key] = value
    return Artifact(path=path, fields=fields, lists=lists)


def frontmatter_dict(path: pathlib.Path, *, require: bool = False) -> dict[str, Any]:
    artifact = parse_frontmatter(path, require=require)
    data: dict[str, Any] = dict(artifact.fields)
    for key, values in artifact.lists.items():
        data[key] = list(values)
    return data


def md_files(root: pathlib.Path, rel_dir: str) -> list[pathlib.Path]:
    directory = root / rel_dir
    if not directory.is_dir():
        return []
    return sorted(path for path in directory.glob("*.md") if path.name != "README.md")


def find_artifact(root: pathlib.Path, dirs: list[str], artifact_id: str) -> Artifact:
    for rel in dirs:
        for path in md_files(root, rel):
            artifact = parse_frontmatter(path)
            if artifact.fields.get("id") == artifact_id:
                return artifact
    raise SystemExit(f"artifact not found: {artifact_id}")


def find_frontmatter_file(
    root: pathlib.Path, dirs: list[str], artifact_id: str, *, required: bool = True
) -> tuple[pathlib.Path, dict[str, Any]] | None:
    for rel in dirs:
        for path in md_files(root, rel):
            data = frontmatter_dict(path)
            if data.get("id") == artifact_id:
                return path, data
    if required:
        raise SystemExit(f"error: artifact not found: {artifact_id}")
    return None


def risk_number(value: str) -> int:
    match = re.fullmatch(r"R([0-5])", value.strip())
    return int(match.group(1)) if match else -1


def risk_lte(left: str, right: str) -> bool:
    left_number = risk_number(left)
    right_number = risk_number(right)
    return left_number >= 0 and right_number >= 0 and left_number <= right_number


def level_number(value: str) -> int:
    match = re.fullmatch(r"L([1-5])", value.strip())
    return int(match.group(1)) if match else 0


def parse_skill(value: str) -> tuple[str, int] | None:
    if ":" not in value:
        return None
    skill, level = value.rsplit(":", 1)
    parsed = level_number(level)
    if not skill or parsed == 0:
        return None
    return skill, parsed


def parse_pipe_record(value: str, width: int) -> list[str]:
    parts = value.split("|")
    while len(parts) < width:
        parts.append("")
    return parts[:width]
