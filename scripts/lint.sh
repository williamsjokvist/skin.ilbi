#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v xmllint >/dev/null; then
  echo "error: xmllint not found (macOS ships it; on Debian: apt install libxml2-utils)" >&2
  exit 1
fi

failed=0

for f in addon.xml colors/*.xml xml/*.xml; do
  xmllint --noout "$f" || failed=$((failed + 1))
done

if [[ $failed -gt 0 ]]; then
  echo "$failed file(s) are not well-formed" >&2
  exit 1
fi

echo "all XML well-formed"
