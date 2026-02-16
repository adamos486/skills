#!/bin/bash
# validate-structural.sh
# Level 1: Structural verification - check that expected files exist.
#
# Usage: ./validate-structural.sh <files-list>
#
# Input: A file containing one path per line (paths relative to project root)
# Output: PASS/FAIL for each file, summary at end
# Exit: 0 if all pass, 1 if any fail

set -euo pipefail

FILES_LIST="${1:-}"

if [ -z "$FILES_LIST" ]; then
  echo "Usage: validate-structural.sh <files-list>"
  echo "  files-list: file with one path per line"
  exit 2
fi

if [ ! -f "$FILES_LIST" ]; then
  echo "ERROR: Files list not found: $FILES_LIST"
  exit 2
fi

PASS_COUNT=0
FAIL_COUNT=0
TOTAL=0

echo "STRUCTURAL VERIFICATION"
echo "======================="
echo ""

while IFS= read -r filepath || [ -n "$filepath" ]; do
  # Skip empty lines and comments
  [ -z "$filepath" ] && continue
  [[ "$filepath" =~ ^# ]] && continue

  TOTAL=$((TOTAL + 1))

  if [ -f "$filepath" ]; then
    echo "  PASS  $filepath"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL  $filepath (not found)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done < "$FILES_LIST"

echo ""
echo "======================="
echo "TOTAL: $TOTAL  PASS: $PASS_COUNT  FAIL: $FAIL_COUNT"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "STRUCTURAL VERIFICATION: PASSED"
  exit 0
else
  echo "STRUCTURAL VERIFICATION: FAILED ($FAIL_COUNT missing files)"
  exit 1
fi
