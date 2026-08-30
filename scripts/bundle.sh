#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

VERSION=$(sed -n 's/.*<addon id="skin.ilbi" version="\([^"]*\)".*/\1/p' addon.xml)

if [[ -z $VERSION ]]; then
  echo "error: could not find the version attribute in addon.xml" >&2
  exit 1
fi

if [[ ! -d fonts ]]; then
  echo "error: no fonts/ directory; run 'mise run install-fonts' first" >&2
  exit 1
fi

ZIP="dist/skin.ilbi-$VERSION.zip"

rm -rf dist
mkdir -p dist/skin.ilbi

# Kodi installs from a zip with a single top-level directory named after the addon.
rsync -a ./ dist/skin.ilbi/ \
  --exclude '.git' \
  --exclude '.github' \
  --exclude '.gitignore' \
  --exclude '.DS_Store' \
  --exclude 'dist' \
  --exclude 'scripts' \
  --exclude 'mise.toml' \
  --exclude 'CLAUDE.md'

(cd dist && zip -qr "skin.ilbi-$VERSION.zip" skin.ilbi)
rm -rf dist/skin.ilbi

echo "  $ZIP"
