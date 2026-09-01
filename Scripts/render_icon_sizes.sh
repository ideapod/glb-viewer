#!/bin/bash
# Downscales a 1024x1024 master PNG (from generate_icon.swift or generate_document_icon.swift)
# into the full set of PNG sizes macOS's asset catalog wants for a "mac" idiom icon set, using
# sips (built into macOS, no extra tools required).
#
# Usage: Scripts/render_icon_sizes.sh <source_1024.png> <dest_appiconset_dir>
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="${1:?Usage: render_icon_sizes.sh <source_1024.png> <dest_appiconset_dir>}"
DIR="${2:?Usage: render_icon_sizes.sh <source_1024.png> <dest_appiconset_dir>}"

declare -a SIZES=(16 32 32 64 128 256 256 512 512 1024)
declare -a NAMES=(
  icon_16x16.png
  icon_16x16@2x.png
  icon_32x32.png
  icon_32x32@2x.png
  icon_128x128.png
  icon_128x128@2x.png
  icon_256x256.png
  icon_256x256@2x.png
  icon_512x512.png
  icon_512x512@2x.png
)

for i in "${!SIZES[@]}"; do
  px="${SIZES[$i]}"
  name="${NAMES[$i]}"
  sips -z "$px" "$px" "$SRC" --out "$DIR/$name" >/dev/null
  echo "Wrote $DIR/$name (${px}x${px})"
done
