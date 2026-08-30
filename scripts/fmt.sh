#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v xmllint >/dev/null; then
  echo "error: xmllint not found (macOS ships it; on Debian: apt install libxml2-utils)" >&2
  exit 1
fi

CHECK=0
if [[ ${1:-} == "--check" ]]; then
  CHECK=1
fi

# Kodi skin XML is tab-indented.
export XMLLINT_INDENT=$'\t'

count=0

for f in addon.xml colors/*.xml xml/*.xml; do
  tmp=$(mktemp)
  if ! xmllint --format "$f" -o "$tmp"; then
    rm -f "$tmp"
    echo "error: $f could not be parsed" >&2
    exit 1
  fi
  if cmp -s "$f" "$tmp"; then
    rm -f "$tmp"
    continue
  fi
  count=$((count + 1))
  if [[ $CHECK == 1 ]]; then
    rm -f "$tmp"
    echo "$f: not formatted" >&2
  else
    mv "$tmp" "$f"
    echo "  $f"
  fi
done

if [[ $CHECK == 1 ]]; then
  if [[ $count -gt 0 ]]; then
    echo "$count file(s) need formatting; run 'mise fmt'" >&2
    exit 1
  fi
  echo "all XML formatted"
else
  echo "$count file(s) reformatted"
fi
