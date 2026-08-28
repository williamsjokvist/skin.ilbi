#!/usr/bin/env bash

set -euo pipefail

SKIN="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -n ${KODI_ADDONS:-} ]]; then
  ADDONS="$KODI_ADDONS"
else
  case "$(uname -s)" in
    Darwin) ADDONS="$HOME/Library/Application Support/Kodi/addons" ;;
    *)      ADDONS="$HOME/.kodi/addons" ;;
  esac
fi

LINK="$ADDONS/skin.ilbi"

if [[ ! -d $ADDONS ]]; then
  echo "error: no Kodi addons directory at $ADDONS" >&2
  echo "       run Kodi once, or pass the path via KODI_ADDONS" >&2
  exit 1
fi

if [[ -L $LINK ]]; then
  ln -sfn "$SKIN" "$LINK"
elif [[ -e $LINK ]]; then
  echo "error: $LINK exists and is not a symlink; move it aside first" >&2
  exit 1
else
  ln -s "$SKIN" "$LINK"
fi

echo "  $LINK -> $SKIN"
echo "Pick it under Settings > Interface > Skin (restart Kodi if it isn't listed)."
