#!/usr/bin/env python3
"""Check Slovenian translations against the English source.

Checks every message: same placeholders and URLs, same number of line breaks,
no empty value, no U+2013/U+2014, no HTML, no value equal to English (except
allowed product names), no ASCII double quotes or "..." in prose, no leftover
"x - y" dash, no missing or unknown keys.

Usage: check.py REPO [NAME ...]   (default: all bundles)
"""
import json
import re
import sys
from pathlib import Path

PARAM = re.compile(r"\{([a-z][A-Za-z0-9]*)\}")
URL = re.compile(r"https?://[^\s,]+")
SAME_OK = {
    "Kiosk Satellite", "Home Assistant", "Voice Satellite", "ESPHome", "Shizuku", "Immich", "Sonos",
    "Music Assistant", "Sendspin", "Go2RTC", "DLNA", "RTSP", "ONVIF", "HACS", "Assist", "OK", "PIN",
    "TLS", "WebView", "RAM", "Ken Burns", "Bluetooth", "GPS", "Wi-Fi", "mDNS", "API", "URL", "JSON",
}


def urls(text):
    return {u.rstrip(".;:!?)]") for u in URL.findall(text)}


def same_ok_keys():
    path = Path(__file__).resolve().parents[1] / "flags.tsv"
    keys = set()
    if path.exists():
        for row in path.read_text(encoding="utf-8").splitlines()[1:]:
            f, k, fl, note = row.split("\t", 3)
            if "enako angleščini" in note:
                keys.add((f, k))
    return keys


def main():
    repo = Path(sys.argv[1])
    allowed_same = same_ok_keys()
    names = sys.argv[2:] or sorted(p.name[:-7] for p in (repo / "source").glob("*_en.arb"))
    problems = 0
    total = 0
    for name in names:
        src = json.loads((repo / "source" / f"{name}_en.arb").read_text())
        path = repo / "translations" / "sl" / f"{name}_sl.arb"
        keys = [k for k in src if not k.startswith("@")]
        if not path.exists():
            print(f"{name}: FILE MISSING")
            problems += 1
            continue
        raw = path.read_text(encoding="utf-8")
        tr = json.loads(raw)
        if next(iter(tr)) != "@@locale" or tr["@@locale"] != "sl":
            print(f"{name}: @@locale must be first and 'sl'")
            problems += 1
        for key in tr:
            if key != "@@locale" and key not in src:
                print(f"{name}.{key}: unknown key")
                problems += 1
            if key.startswith("@") and key != "@@locale":
                print(f"{name}.{key}: metadata block not allowed")
                problems += 1
        for key in keys:
            en = src[key]
            if key not in tr:
                print(f"{name}.{key}: missing")
                problems += 1
                continue
            sl = tr[key]
            total += 1
            issues = []
            if not isinstance(sl, str) or not sl.strip():
                issues.append("empty")
            else:
                if sorted(PARAM.findall(sl)) != sorted(PARAM.findall(en)):
                    issues.append(f"placeholders {PARAM.findall(en)} -> {PARAM.findall(sl)}")
                if "{" in PARAM.sub("", sl) or "}" in PARAM.sub("", sl):
                    issues.append("stray brace")
                if urls(sl) != urls(en):
                    issues.append(f"urls {urls(en)} -> {urls(sl)}")
                if sl.count("\n") != en.count("\n"):
                    issues.append(f"line breaks {en.count(chr(10))} -> {sl.count(chr(10))}")
                if re.search("[–—]", sl):
                    issues.append("en/em dash")
                if re.search(r"<[^>]+>", sl):
                    issues.append("html")
                if re.search(r"[\x00-\x08\x0b\x0c\x0e-\x1f]", sl):
                    issues.append("control char")
                if sl == en and sl not in SAME_OK and (name, key) not in allowed_same and PARAM.sub("", sl).strip(" :%°C,.()-/·") != "":
                    issues.append("identical to English")
                prose = URL.sub("", sl)
                if '"' in prose and "document." not in sl:
                    issues.append("ASCII double quote")
                if "..." in prose:
                    issues.append("three dots")
                if re.search(r"[A-Za-zčšžćđČŠŽĆĐ]…", sl):
                    issues.append("ellipsis without space")
                if " - " in sl:
                    issues.append("spaced hyphen used as dash")
                if re.search(r"[\d}]%", sl):
                    issues.append("percent without space")
                if sl != sl.strip():
                    if not (en.startswith(" ") and sl.startswith(" ")) and not (en.endswith(" ") and sl.endswith(" ")):
                        issues.append("leading/trailing space")
            if issues:
                problems += 1
                print(f"{name}.{key}: {'; '.join(issues)}\n    EN: {en!r}\n    SL: {sl!r}")
    print(f"checked {total} messages in {len(names)} files, {problems} problems")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
