#!/usr/bin/env python3
"""Palari OpenRouter executor adapter.

Runs one ticket packet against an OpenRouter model and writes the response
into the ticket's evidence directory. This executor produces *text
artifacts* (analysis, drafts, reviews, decision write-ups); it never edits
repository files, so scope-check passes trivially and the output is judged
through the normal report/review lifecycle.

Determinism and policy, enforced fail-closed in this adapter:
  - The model must come from Palari's routing (risk tier -> class ->
    model_<class>_openrouter) or an explicit hint, AND must appear in the
    config allowlist (`openrouter_allowed_models`) when one is set.
  - The API key is read from the environment variable named by
    `openrouter_api_key_env` (default OPENROUTER_API_KEY) and is never
    written to disk or into evidence.
  - Requests use temperature 0 and a fixed seed by default so identical
    packets produce stable outputs where the upstream model supports it.

Advisor (strong-helps-weak): when `openrouter_advisor_model` is configured,
the request includes OpenRouter's `openrouter:advisor` server tool, letting
a cheap executor model consult a stronger one mid-generation and pay
frontier prices only for the hard moments. See
https://openrouter.ai/blog/announcements/advisor-server-tool/

Testing: set PALARI_OPENROUTER_TRANSPORT=file:/path/to/response.json to
bypass HTTP entirely; the adapter reads that file as the API response.
`--dry-run` prints the redacted request payload and exits without any
network access.
"""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

DEFAULT_BASE_URL = "https://openrouter.ai/api/v1"
ERROR_MESSAGES = {
    "unknown_option": "unknown or incomplete option",
    "disabled": "openrouter_enabled is false in palari.config.yaml; enable it to use this executor",
    "no_model": "no model resolved; configure model_<class>_openrouter mappings or pass --model",
    "model_not_allowed": "model is not in openrouter_allowed_models; routing is deterministic and fail-closed",
    "missing_api_key": "missing API key: set the configured OpenRouter API key environment variable (default OPENROUTER_API_KEY); the key is never stored in the repo",
    "api_error": "API error; response body suppressed",
    "network_error": "network error while contacting OpenRouter",
}


def read_config(root: Path) -> dict:
    flat: dict = {}
    lists: dict = {}
    current_list = None
    for raw in (root / "palari.config.yaml").read_text(encoding="utf-8").split("\n"):
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if raw.startswith((" ", "\t")):
            line = raw.strip()
            if line.startswith("- ") and current_list:
                lists[current_list].append(line[2:].strip().strip("'\""))
            continue
        match = re.match(r"^([A-Za-z0-9_]+):\s*(.*)$", raw.strip())
        if not match:
            current_list = None
            continue
        key, value = match.group(1), re.sub(r"\s+#.*$", "", match.group(2)).strip()
        if value == "":
            current_list = key
            lists[key] = []
        else:
            current_list = None
            flat[key] = value.strip("'\"")
    return {"flat": flat, "lists": lists}


def fail(code: str) -> None:
    print(f"openrouter: {ERROR_MESSAGES.get(code, 'execution failed')}", file=sys.stderr)
    raise SystemExit(2)


def main() -> int:
    args = sys.argv[1:]
    options = {"root": ".", "ticket": "", "packet": "", "model": "", "out": "", "prompt": ""}
    dry_run = False
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--dry-run":
            dry_run = True
            i += 1
            continue
        key = arg.lstrip("-")
        if key not in options or i + 1 >= len(args):
            fail("unknown_option")
        options[key] = args[i + 1]
        i += 2

    root = Path(options["root"]).resolve()
    config = read_config(root)
    flat, lists = config["flat"], config["lists"]

    if flat.get("openrouter_enabled", "false") != "true":
        fail("disabled")

    model = options["model"]
    if not model:
        fail("no_model")

    allowed = [m for m in lists.get("openrouter_allowed_models", []) if m]
    if allowed and model not in allowed:
        fail("model_not_allowed")

    packet_path = Path(options["packet"]) if options["packet"] else None
    packet_text = packet_path.read_text(encoding="utf-8") if packet_path and packet_path.is_file() else ""
    user_prompt = options["prompt"] or (
        "Execute this Palari packet. Produce your complete written deliverable "
        "(analysis, draft, review, or decision write-up). You cannot edit files; "
        "everything must be in your response."
    )

    messages = [
        {
            "role": "system",
            "content": (
                "You are a Palari specialist executor working under repo-native "
                "governance. Stay strictly within the packet's scope and authority. "
                "Never invent file edits, acceptances, or evidence; your entire "
                "output is a text artifact that a fresh reviewer will judge."
            ),
        },
        {"role": "user", "content": f"{user_prompt}\n\n--- PACKET ---\n{packet_text}"},
    ]

    payload: dict = {
        "model": model,
        "messages": messages,
        "temperature": float(flat.get("openrouter_temperature", "0")),
    }
    seed = flat.get("openrouter_seed", "7")
    if seed:
        payload["seed"] = int(seed)
    max_tokens = flat.get("openrouter_max_tokens", "")
    if max_tokens:
        payload["max_tokens"] = int(max_tokens)

    advisor_model = flat.get("openrouter_advisor_model", "")
    if advisor_model:
        advisor: dict = {"type": "openrouter:advisor", "parameters": {"model": advisor_model}}
        instructions = flat.get("openrouter_advisor_instructions", "")
        name = flat.get("openrouter_advisor_name", "")
        if name:
            advisor["parameters"]["name"] = name
        if instructions:
            advisor["parameters"]["instructions"] = instructions
        payload["tools"] = [advisor]

    if dry_run:
        print(json.dumps({"endpoint": f"{flat.get('openrouter_base_url', DEFAULT_BASE_URL)}/chat/completions", "payload": payload}, indent=2))
        return 0

    out_dir = Path(options["out"]) if options["out"] else None
    if out_dir:
        out_dir.mkdir(parents=True, exist_ok=True)
        (out_dir / "request.json").write_text(json.dumps(payload, indent=2), encoding="utf-8")

    transport = os.environ.get("PALARI_OPENROUTER_TRANSPORT", "")
    if transport.startswith("file:"):
        response_data = json.loads(Path(transport[5:]).read_text(encoding="utf-8"))
    else:
        key_env = flat.get("openrouter_api_key_env", "OPENROUTER_API_KEY")
        api_key = os.environ.get(key_env, "")
        if not api_key:
            fail("missing_api_key")
        request = urllib.request.Request(
            f"{flat.get('openrouter_base_url', DEFAULT_BASE_URL)}/chat/completions",
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://github.com/CoyStan/palari-orchestrator",
                "X-Title": "Palari Orchestrator",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=int(flat.get("openrouter_timeout_seconds", "300"))) as response:
                response_data = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            # Provider error bodies can contain echoed request details. Keep
            # evidence useful without writing possible secrets to stderr.
            fail("api_error")
        except (urllib.error.URLError, TimeoutError) as exc:
            fail("network_error")

    choices = response_data.get("choices") or []
    text = choices[0].get("message", {}).get("content", "") if choices else ""
    usage = response_data.get("usage", {})

    if out_dir:
        (out_dir / "response.json").write_text(json.dumps(response_data, indent=2), encoding="utf-8")
        (out_dir / "usage.json").write_text(
            json.dumps({"model": model, "advisor_model": advisor_model or None, "usage": usage}, indent=2),
            encoding="utf-8",
        )
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
