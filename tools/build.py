#!/usr/bin/env python3
"""Write translations/sl/*_sl.arb from a batch file and record review flags.

Batch file format:
    # file: <name>            (bundle name without _en.arb)
    key = value               (\\n in value means a line break;
                               "..." is a JSON string, for leading/trailing spaces)
    !key FLAG note            (FLAG: N uncertain, S rephrased for numbers,
                               P placeholder with a case noun, O other)
Existing translations are kept unless the batch overrides them. Keys are
written in source order after "@@locale": "sl".

Usage: build.py REPO NOTES_DIR BATCH_FILE
"""
import json
import re
import sys
from pathlib import Path

FLAGS = {"N": "negotovo", "S": "preoblikovano zaradi števila", "P": "placeholder v sklonu", "O": "drugo"}


def parse(path):
    files, flags, current = {}, [], None
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.rstrip("\n")
        if not line.strip():
            continue
        m = re.match(r"#\s*file:\s*(\S+)", line)
        if m:
            current = m.group(1)
            files.setdefault(current, {})
            continue
        if line.startswith("#"):
            continue
        if line.startswith("!"):
            key, flag, *note = line[1:].split(" ", 2)
            if flag not in FLAGS:
                sys.exit(f"Unknown flag {flag} in: {line}")
            flags.append((current, key, flag, note[0] if note else ""))
            continue
        if " = " not in line or current is None:
            sys.exit(f"Cannot parse: {line}")
        key, value = line.split(" = ", 1)
        key = key.strip()
        if key in files[current]:
            sys.exit(f"Duplicate key {key} in {current}")
        if len(value) > 1 and value.startswith('"') and value.endswith('"'):
            files[current][key] = json.loads(value)
        else:
            files[current][key] = value.replace("\\n", "\n")
    return files, flags


def main():
    repo, notes, batch = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
    files, flags = parse(batch)
    for name, values in files.items():
        src = json.loads((repo / "source" / f"{name}_en.arb").read_text())
        order = [k for k in src if not k.startswith("@")]
        unknown = set(values) - set(order)
        if unknown:
            sys.exit(f"{name}: unknown keys {sorted(unknown)}")
        target = repo / "translations" / "sl" / f"{name}_sl.arb"
        existing = json.loads(target.read_text()) if target.exists() else {}
        merged = {**{k: v for k, v in existing.items() if k != "@@locale"}, **values}
        out = {"@@locale": "sl", **{k: merged[k] for k in order if k in merged}}
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        missing = [k for k in order if k not in merged]
        print(f"{name}: {len(out) - 1}/{len(order)}" + (f" MISSING {missing}" if missing else ""))
    flag_path = notes / "flags.tsv"
    rows = {}
    if flag_path.exists():
        for row in flag_path.read_text(encoding="utf-8").splitlines()[1:]:
            f, k, fl, note = row.split("\t", 3)
            rows[(f, k, fl)] = note
    for f, k, fl, note in flags:
        rows[(f, k, FLAGS[fl])] = note
    lines = ["file\tkey\tflag\tnote"] + [f"{f}\t{k}\t{fl}\t{n}" for (f, k, fl), n in sorted(rows.items())]
    flag_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
