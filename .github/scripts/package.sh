#!/usr/bin/env bash
# zips every top-level theme folder into dist/<name>.zip, with the folder itself at the root of the
# zip so it extracts straight into ghlarp/themes. also zips all of them together into
# dist/All_Themes.zip so grabbing everything is one download instead of a pile of rate-limited ones.
# writes dist/notes.md for the release body.
set -euo pipefail

out=dist
all=All_Themes.zip
rm -rf "$out"
mkdir -p "$out"

echo "these go into ghlarp/themes then you can just refresh themes in the gui if the game is already running." > "$out/notes.md"

themes=()
count=0
for dir in */; do
  name="${dir%/}"
  # only theme folders: a settings.ini or a Notes folder, skip dist and dot folders
  [[ "$name" == "$out" || "$name" == .* ]] && continue
  [[ -f "$name/settings.ini" || -d "$name/Notes" ]] || continue

  # github mangles spaces and symbols in asset names, so pick a safe one ourselves
  asset="$(printf '%s' "$name" | sed -E 's/[^A-Za-z0-9._-]+/_/g; s/^_+|_+$//g').zip"
  if [[ "$asset" == "$all" ]]; then
    echo "theme folder \"$name\" would overwrite $all, rename it" >&2
    exit 1
  fi
  zip -q -r -X "$out/$asset" "$name" -x '*/Thumbs.db' '*/desktop.ini' '*/.DS_Store'
  themes+=("$name")
  count=$((count + 1))
done

if [[ $count -eq 0 ]]; then
  echo "no theme folders found" >&2
  exit 1
fi

zip -q -r -X "$out/$all" "${themes[@]}" -x '*/Thumbs.db' '*/desktop.ini' '*/.DS_Store'
echo "packaged $count themes, plus $all"
