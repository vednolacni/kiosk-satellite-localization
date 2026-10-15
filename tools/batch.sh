#!/usr/bin/env bash
# Build, check, validate and commit one translation batch.
# Usage: batch.sh N BATCH_FILE "commit message" "progress note"
set -euo pipefail
N=$1; FILE=$2; MSG=$3; NOTE=$4
REPO=/home/user/kiosk-satellite-localization
NOTES=/home/user/sl-notes
LINE=$(sed -n "${N}p" "$NOTES/batches.txt")
NAMES=$(echo "$LINE" | cut -d: -f2-)
ID=$(echo "$LINE" | cut -d' ' -f1)
cd "$REPO"
python3 "$NOTES/tools/build.py" "$REPO" "$NOTES" "$FILE"
python3 "$NOTES/tools/check.py" "$REPO" $NAMES
python3 tools/catalog.py validate > /dev/null && echo "catalog.py validate: OK"
python3 tools/catalog.py validate | grep -E '^sl: '
git add translations/sl
git commit -qm "$MSG"
git push -q origin sl 2>&1 | grep -v '^remote:' || true
HASH=$(git rev-parse --short HEAD)
FILES=$(echo $NAMES | wc -w)
MSGS=$(python3 -c "import json,sys;print(sum(len([k for k in json.load(open(f'source/{n}_en.arb')) if not k.startswith('@')]) for n in sys.argv[1:]))" $NAMES)
cd "$NOTES"
echo "| $ID | $FILES datotek, $MSGS sporočil ($(echo $NAMES | cut -d' ' -f1) do $(echo $NAMES | awk '{print $NF}')) | \`$HASH\` | OK, check.py 0 težav | $NOTE |" >> progress.md
git add -A
git commit -qm "Record batch $ID progress, flags and glossary additions"
git push -q 2>&1 | grep -v '^remote:' || true
echo "done: $ID $HASH"
