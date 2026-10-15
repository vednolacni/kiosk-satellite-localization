#!/usr/bin/env python3
"""Terminology consistency scan over translations/sl.

Usage: terms.py REPO

Prints every value that matches a pattern for a variant the glossary
rules out (declined product names, rejected synonyms, English leftovers,
mid-sentence Title Case of common words), grouped by rule.
"""
import glob
import json
import os
import re
import sys

RULES = [
    # (label, regex applied to the Slovenian value, flags)
    ("declined product name (D1)", r"\b(Home Assistant(a|u|om)|Kiosk Satellit(a|u|om)\b|Voice Satellit(a|u|om)|ESPHom(a|u|om)|Shizuk(ja|ju|jem)|Immich(a|u|em)|Sonos(a|u|om)|Music Assistant(a|u|om)|Sendspin(a|u|om)|Go2RTC-|HACS-|GitHub(a|u|om)|Github)\b", 0),
    ("drawer must be meni kioska (D4)", r"\bpredal", re.I),
    ("wake word must be aktivacijska beseda (D2)", r"beseda za bujenje|budilna beseda|besed[ae] za prebujanje", re.I),
    ("admin must be skrbništvo (D3)", r"administra", re.I),
    ("intercom must be interkom (D8)", r"domofon|interfon", re.I),
    ("media must be mediji (D9)", r"predstavnost", re.I),
    ("tablet must be tablica (D10)", r"tablični računalnik", re.I),
    ("gesture must be kretnja", r"\bgest[aeio]?\b|\bgeste\b", re.I),
    ("dashboard must be nadzorna plošča", r"armaturn|instrumentn", re.I),
    ("volume must be glasnost", r"\bjakost", re.I),
    ("brightness must be svetlost", r"svetilnost|osvetljenost", re.I),
    ("plugin must be vtičnik", r"\bdodat(ek|ka|ki|kov)\b|\bplugin", re.I),
    ("certificate must be potrdilo", r"certifikat", re.I),
    ("token must be žeton", r"\btoken", re.I),
    ("screensaver must be ohranjevalnik zaslona", r"ohranjevalnik(?! zaslona)(?!a zaslona)(?!u zaslona)(?!om zaslona)(?!i zaslona)(?!ov zaslona)(?!ih zaslona)(?!e zaslona)(?!ih)", re.I),
    ("permission must be dovoljenje", r"\bpravic", re.I),
    ("Wi-Fi spelling", r"\bwifi\b|\bWiFi\b|\bWLAN\b", re.I),
    ("English leftover word", r"\b(the|and|with|from|your|this|settings|enable|disable|screen|device|please|click|tap|button|error|failed|loading)\b", 0),
    ("Title Case common word mid-string", r"(?<=[a-zčšž,] )(Nastavitve|Zaslon|Naprava|Ohranjevalnik|Nadzorna|Pogled|Kamera|Glasnost|Svetlost)\b(?! →)", 0),
    ("straight or other quotes", r"[\"„“”‘’]", 0),
    ("Uninstall must be Odmesti (Android apps)", r"\bodinstal|\bdeinstal", re.I),
    ("follow-up variants", r"nadaljnj[a-z]* vprašanj|sledilno vprašanj", re.I),
]

SKIP_QUOTE_KEYS = {"browserInjectJsPlaceholder", "browserInjectJsExternalPlaceholder"}


def main():
    repo = sys.argv[1]
    hits = {label: [] for label, _, _ in RULES}
    compiled = [(label, re.compile(rx, fl)) for label, rx, fl in RULES]
    for path in sorted(glob.glob(os.path.join(repo, "translations", "sl", "*_sl.arb"))):
        name = os.path.basename(path)[:-7]
        data = json.load(open(path, encoding="utf-8"))
        for key, value in data.items():
            if key.startswith("@"):
                continue
            for label, rx in compiled:
                if label.startswith("straight") and key in SKIP_QUOTE_KEYS:
                    continue
                if rx.search(value):
                    hits[label].append(f"{name}.{key}: {value}")
    for label, items in hits.items():
        print(f"== {label}: {len(items)}")
        for item in items:
            print("   " + item)


if __name__ == "__main__":
    main()
