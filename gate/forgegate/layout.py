"""Layouts.

A layout declares, per ticket type, what governed work must look like:

    name: code-change
    steps:
      - name: implement
      - name: test
        consumes: [implement]        # hash flow: test's inputs must include
                                     # implement's outputs, byte for byte
      - name: review
        consumes: [test]
        distinct_from: [implement]   # dual control: a different key than
                                     # the one that implemented
        optional_context: [paths]    # exempt a constrained dimension from
                                     # FG-CONSTRAINT-001 for this step only

Layouts are data. They are loaded from YAML or JSON and validated; they carry
no code and no authority of their own. The gate interprets them.
"""
import json

try:
    import yaml
except ImportError:  # pragma: no cover
    yaml = None


class LayoutError(ValueError):
    pass


def validate(layout: dict) -> dict:
    if not isinstance(layout, dict) or "steps" not in layout:
        raise LayoutError("layout must be a mapping with a 'steps' list")
    names = []
    for s in layout["steps"]:
        if "name" not in s:
            raise LayoutError("every step needs a name")
        if s["name"] in names:
            raise LayoutError(f"duplicate step name: {s['name']}")
        for ref_field in ("consumes", "distinct_from"):
            for ref in s.get(ref_field, []):
                if ref not in names:
                    raise LayoutError(
                        f"step '{s['name']}' references '{ref}' "
                        f"in {ref_field} before it is defined"
                    )
        names.append(s["name"])
    return layout


def load(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    if path.endswith((".yml", ".yaml")) and yaml is not None:
        return validate(yaml.safe_load(text))
    return validate(json.loads(text))


def step_names(layout: dict) -> list[str]:
    return [s["name"] for s in layout["steps"]]
