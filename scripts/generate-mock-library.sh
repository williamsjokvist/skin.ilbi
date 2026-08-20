#!/usr/bin/env bash

set -euo pipefail

ROOT="${1:-$HOME/Videos/Kodi Mock Library}"
MOVIES="$ROOT/Movies"
SHOWS="$ROOT/TV Shows"

mkclip() {
  local dest=$1
  mkdir -p "$(dirname "$dest")"
  [[ -f $dest ]] && return 0
  ffmpeg -loglevel error -y \
    -f lavfi -i "color=c=black:s=640x360:r=24:d=1" \
    -f lavfi -i "anullsrc=r=48000:cl=stereo" \
    -shortest -t 1 -c:v libx264 -pix_fmt yuv420p -c:a aac "$dest"
  echo "  ${dest#"$ROOT"/}"
}

echo "Movies:"
while IFS= read -r title; do
  [[ -z $title ]] && continue
  mkclip "$MOVIES/$title/$title.mkv"
done <<'MOVIELIST'
The Matrix (1999)
Spirited Away (2001)
The Social Network (2010)
Inception (2010)
Mad Max Fury Road (2015)
The Grand Budapest Hotel (2014)
Whiplash (2014)
Arrival (2016)
Blade Runner 2049 (2017)
Parasite (2019)
Dune (2021)
Everything Everywhere All at Once (2022)
MOVIELIST

echo "TV shows:"
while IFS= read -r line; do
  [[ -z $line ]] && continue
  show=${line%%|*}; episodes=${line#*|}
  for ep in $episodes; do
    season=${ep%%E*}; season=${season#S}
    mkclip "$SHOWS/$show/Season ${season}/$show - $ep.mkv"
  done
done <<'SHOWLIST'
Breaking Bad|S01E01 S01E02 S01E03 S02E01 S02E02
Chernobyl|S01E01 S01E02 S01E03
Severance|S01E01 S01E02 S01E03
The Bear|S01E01 S01E02 S01E03
SHOWLIST

i=0
find "$ROOT" -name '*.mkv' -print0 | while IFS= read -r -d '' f; do
  touch -t "$(date -v-"${i}"d '+%Y%m%d%H%M')" "$f"
  i=$((i + 1))
done

echo
echo "Root: $ROOT"
find "$ROOT" -name '*.mkv' | wc -l | xargs echo "Clips:"
du -sh "$ROOT" | cut -f1 | xargs echo "Size:"
