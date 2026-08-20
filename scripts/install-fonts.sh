#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p fonts

fetch() {
  local family=$1 weight=$2 dest=$3 url
  url=$(curl -fsS "https://fonts.googleapis.com/css2?family=${family}:wght@${weight}" \
        | grep -oE 'https://[^)]+\.ttf' | head -1)
  if [[ -z $url ]]; then
    echo "error: no ttf returned for ${family} @ ${weight}" >&2
    return 1
  fi
  curl -fsS -o "fonts/${dest}" "$url"
  echo "  fonts/${dest}"
}

echo "Nunito:"
fetch Nunito 300 Nunito-Light.ttf
fetch Nunito 400 Nunito-Regular.ttf
fetch Nunito 500 Nunito-Medium.ttf
fetch Nunito 600 Nunito-SemiBold.ttf

echo "Noto Sans Mono:"
fetch Noto+Sans+Mono 400 NotoSansMono-Regular.ttf

echo "Licences:"
for pair in nunito:nunito_license.txt notosansmono:noto_license.txt; do
  curl -fsS -o "fonts/${pair#*:}" \
    "https://raw.githubusercontent.com/google/fonts/main/ofl/${pair%%:*}/OFL.txt"
  echo "  fonts/${pair#*:}"
done
