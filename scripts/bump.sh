#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:-}"

if [[ -z $VERSION ]]; then
  echo "usage: mise run bump <version>   e.g. mise run bump 0.1.0" >&2
  exit 1
fi

VERSION="${VERSION#v}"

if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+([~+.-][0-9A-Za-z.-]+)?$ ]]; then
  echo "error: '$VERSION' is not a valid addon version" >&2
  exit 1
fi

CURRENT=$(sed -n 's/.*<addon id="skin.ilbi" version="\([^"]*\)".*/\1/p' addon.xml)

if [[ -z $CURRENT ]]; then
  echo "error: could not find the version attribute in addon.xml" >&2
  exit 1
fi

if [[ $CURRENT == "$VERSION" ]]; then
  echo "addon.xml is already at $VERSION"
  exit 0
fi

sed -i.bak "1,/<addon /s/\(<addon id=\"skin.ilbi\" version=\"\)[^\"]*\"/\1$VERSION\"/" addon.xml
rm -f addon.xml.bak

echo "  addon.xml $CURRENT -> $VERSION"

if ! grep -qF "[B]$VERSION[/B]" changelog.txt; then
  echo "note: changelog.txt has no [B]$VERSION[/B] section yet"
fi

echo "Then: git commit -am \"chore: release $VERSION\" && git tag v$VERSION && git push --follow-tags"
