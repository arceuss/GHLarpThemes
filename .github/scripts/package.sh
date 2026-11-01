#!/usr/bin/env bash
# zips every top-level theme folder into dist/<name>.zip, with the folder itself at the root of the
# zip so it extracts straight into gh3larp/themes. also zips all of them together into
# dist/All_Themes.zip so grabbing everything is one download instead of a pile of rate-limited ones.
# writes dist/notes.md for the release body; DOWNLOAD_URL (the release's download folder) makes its
# links absolute, so they keep pointing at this release's zips after newer ones come out.
set -euo pipefail

out=dist
all=All_Themes.zip
rm -rf "$out"
mkdir -p "$out"

{
  echo "Each zip is one theme. Extract it into \`gh3larp/themes\` in your Clone Hero folder, then pick it in the GH3Larp menu (Refresh themes if the game is already running)."
  echo
  echo "| Theme | Download | Needs |"
  echo "|---|---|---|"
} > "$out/notes.md"

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

  # [theme] fallback=<name> means the theme borrows art from another one it doesn't ship
  needs="$(awk 'BEGIN{IGNORECASE=1} /^\[/{s=tolower($0)=="[theme]"} s && /^[ \t]*fallback[ \t]*=/{sub(/^[^=]*=[ \t]*/,""); sub(/[ \t\r]+$/,""); print}' "$name/settings.ini" 2>/dev/null || true)"
  echo "| $name | [$asset](${DOWNLOAD_URL:-.}/$asset) | ${needs:-} |" >> "$out/notes.md"
  count=$((count + 1))
done

if [[ $count -eq 0 ]]; then
  echo "no theme folders found" >&2
  exit 1
fi

zip -q -r -X "$out/$all" "${themes[@]}" -x '*/Thumbs.db' '*/desktop.ini' '*/.DS_Store'
echo >> "$out/notes.md"
echo "Want all of them? [$all](${DOWNLOAD_URL:-.}/$all) has every theme above in one zip; extract it into the same folder." >> "$out/notes.md"
echo "packaged $count themes, plus $all"
