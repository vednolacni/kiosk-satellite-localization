#!/usr/bin/env python3
"""Independent whole-catalog verification of translations/sl against source/.

Usage: verify.py REPO [FLAGS_TSV]

Errors (exit 1): missing/unknown/empty keys, @ blocks, wrong @@locale,
placeholder, brace, URL or newline mismatch, U+2013/U+2014, HTML tags,
control characters.
Warnings (reported, exit 0): values identical to English that are not
whitelisted in flags.tsv, final punctuation mismatch, double spaces,
non-breaking spaces, straight double quotes, three ASCII dots,
leading/trailing whitespace differences.
"""
import collections
import glob
import json
import os
import re
import sys

PARAM = re.compile(r"\{([a-z][A-Za-z0-9]*)\}")
URL = re.compile(r"https?://[^\s,]+")
HTML = re.compile(r"</?[A-Za-z][A-Za-z0-9-]*(\s[^<>]*)?/?>")
CTRL = re.compile(r"[\x00-\x09\x0b-\x1f\x7f]")
DASHES = "–—"


def urls(text):
    return collections.Counter(u.rstrip(".,;:!?)\"'»") for u in URL.findall(text))


def final_punct(text):
    t = text.rstrip()
    return t[-1] if t and t[-1] in ".:?!…" else ""


def main():
    repo = sys.argv[1]
    flags_path = sys.argv[2] if len(sys.argv) > 2 else None
    whitelist = set()
    if flags_path and os.path.exists(flags_path):
        for line in open(flags_path, encoding="utf-8"):
            parts = line.rstrip("\n").split("\t")
            if len(parts) >= 4 and "enako angleščini" in parts[3]:
                whitelist.add((parts[0], parts[1]))

    errors, warnings = [], []
    total = 0
    sources = sorted(glob.glob(os.path.join(repo, "source", "*_en.arb")))
    seen_sl = set()
    for src_path in sources:
        name = os.path.basename(src_path)[: -len("_en.arb")]
        sl_path = os.path.join(repo, "translations", "sl", name + "_sl.arb")
        seen_sl.add(os.path.basename(sl_path))
        src = json.load(open(src_path, encoding="utf-8"))
        msgs = {k: v for k, v in src.items() if not k.startswith("@")}
        if not os.path.exists(sl_path):
            errors.append(f"{name}: file missing")
            continue
        raw = open(sl_path, encoding="utf-8").read()
        try:
            sl = json.loads(raw, object_pairs_hook=collections.OrderedDict)
        except ValueError as e:
            errors.append(f"{name}: invalid JSON: {e}")
            continue
        keys = list(sl.keys())
        if not keys or keys[0] != "@@locale" or sl.get("@@locale") != "sl":
            errors.append(f"{name}: @@locale must be first and equal to sl")
        for k in keys:
            if k.startswith("@") and k != "@@locale":
                errors.append(f"{name}.{k}: metadata block present")
            elif not k.startswith("@") and k not in msgs:
                errors.append(f"{name}.{k}: unknown key")
        order = [k for k in keys if not k.startswith("@")]
        if order != [k for k in msgs if k in sl]:
            warnings.append(f"{name}: key order differs from source")
        for key, en in msgs.items():
            total += 1
            where = f"{name}.{key}"
            if key not in sl:
                errors.append(f"{where}: missing")
                continue
            tr = sl[key]
            if not isinstance(tr, str) or not tr.strip():
                errors.append(f"{where}: empty or not a string")
                continue
            if collections.Counter(PARAM.findall(en)) != collections.Counter(PARAM.findall(tr)):
                errors.append(f"{where}: placeholders {sorted(PARAM.findall(en))} vs {sorted(PARAM.findall(tr))}")
            if PARAM.sub("", tr).count("{") or PARAM.sub("", tr).count("}"):
                errors.append(f"{where}: stray brace")
            if urls(en) != urls(tr):
                errors.append(f"{where}: URLs {dict(urls(en))} vs {dict(urls(tr))}")
            if en.count("\n") != tr.count("\n"):
                errors.append(f"{where}: newline count {en.count(chr(10))} vs {tr.count(chr(10))}")
            if any(c in tr for c in DASHES):
                errors.append(f"{where}: forbidden dash")
            if HTML.search(tr) and not HTML.search(en):
                errors.append(f"{where}: HTML tag")
            if CTRL.search(tr):
                errors.append(f"{where}: control character")
            if tr == en and (name, key) not in whitelist:
                warnings.append(f"{where}: identical to English: {tr!r}")
            if final_punct(en) != final_punct(tr) and not (final_punct(en) == "" and tr.rstrip().endswith("…")):
                warnings.append(f"{where}: final punctuation {final_punct(en)!r} vs {final_punct(tr)!r}: {tr!r}")
            if "  " in tr and "  " not in en:
                warnings.append(f"{where}: double space")
            if " " in tr:
                warnings.append(f"{where}: non-breaking space")
            if '"' in tr and "document." not in tr:
                warnings.append(f"{where}: straight double quote")
            if "..." in tr:
                warnings.append(f"{where}: three ASCII dots")
            if (en[:1].isspace(), en[-1:].isspace()) != (tr[:1].isspace(), tr[-1:].isspace()):
                warnings.append(f"{where}: leading/trailing whitespace differs")
    extra = sorted(set(os.listdir(os.path.join(repo, "translations", "sl"))) - seen_sl)
    for e in extra:
        errors.append(f"translations/sl/{e}: file without source")

    for w in warnings:
        print("WARN ", w)
    for e in errors:
        print("ERROR", e)
    print(f"verified {total} messages in {len(sources)} files: {len(errors)} errors, {len(warnings)} warnings")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
