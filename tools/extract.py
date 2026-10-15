#!/usr/bin/env python3
"""Print source messages of the given bundles in a compact form for translating.

Usage: extract.py REPO NAME [NAME ...]   (NAME without _en.arb)
"""
import json
import sys
from pathlib import Path

GENERIC = {
    "Setting label.", "Help below the setting.", "Help below this setting.",
    "Visible label, help or status in this section.", "Label or guidance in this section.",
    "Label or explanation on this Device settings page.", "Interface label or status message.",
    "Translate the visible label or help. Keep model names and technical identifiers unchanged.",
    "Translate the visible label or help. Keep Voice Satellite, Kiosk Satellite, Home Assistant, ESPHome, HACS and model names unchanged.",
    "Translate the interface text. Keep external names, versions and technical details unchanged.",
    "Translate the visible message. Keep placeholders and any technical names unchanged.",
    "Label, status or guidance in this section.", "Heading, choice, status or guidance shown in this group.",
}


def main():
    repo = Path(sys.argv[1])
    for name in sys.argv[2:]:
        src = json.loads((repo / "source" / f"{name}_en.arb").read_text())
        keys = [k for k in src if not k.startswith("@")]
        print(f"# file: {name}  ({len(keys)})")
        last_ctx = None
        last_notes = None
        last_locs = None
        for key in keys:
            meta = src.get("@" + key, {})
            ctx = meta.get("context", "")
            if ctx != last_ctx:
                print(f"  [C] {ctx}")
                last_ctx = ctx
            desc = meta.get("description", "")
            notes = meta.get("x-notes")
            print(f"{key} = {json.dumps(src[key], ensure_ascii=False)[1:-1]}")
            if desc and desc not in GENERIC:
                print(f"    D: {desc}")
            if notes and notes != last_notes:
                print(f"    N: {notes}")
            last_notes = notes
            locs = meta.get("x-locations")
            if locs and locs != last_locs:
                print(f"    L: {json.dumps(locs, ensure_ascii=False)[:300]}")
            last_locs = locs
        print()


if __name__ == "__main__":
    main()
