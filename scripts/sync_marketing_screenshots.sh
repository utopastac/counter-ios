#!/usr/bin/env bash
# Sync App Store iPhone screenshots into the Numo marketing gallery.
#
# Expects captures from `fastlane screenshots` under ./screenshots/en-US/.
# Writes PNGs into the sibling numo-website repo (override with NUMO_WEB_ROOT).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${SCREENSHOTS_DIR:-$ROOT/screenshots/en-US}"
WEB_ROOT="${NUMO_WEB_ROOT:-$ROOT/../numo-website}"
DEST_DIR="$WEB_ROOT/public/images"

# Match existing gallery asset size (iPhone 18 Pro Max @3x crop).
WEB_W=1206
WEB_H=2622

DEVICE_PREFIX="iPhone 18 Pro Max"

# Snapshot name → website gallery filename (see numo-website/src/data/screenshots.ts).
declare -a MAP=(
  "01-Pager:protein.png"
  "02-List:list-normal.png"
  "03-History:history.png"
  "04-Compact:compact.png"
)

if [[ ! -d "$SRC_DIR" ]]; then
  echo "error: missing screenshots dir: $SRC_DIR" >&2
  echo "Run \`fastlane screenshots\` first." >&2
  exit 1
fi

if [[ ! -d "$DEST_DIR" ]]; then
  echo "error: marketing gallery not found: $DEST_DIR" >&2
  echo "Set NUMO_WEB_ROOT to your numo-website checkout." >&2
  exit 1
fi

echo "Syncing iPhone screenshots → $DEST_DIR"
for entry in "${MAP[@]}"; do
  name="${entry%%:*}"
  dest_name="${entry##*:}"
  src="$SRC_DIR/${DEVICE_PREFIX}-${name}.png"
  dest="$DEST_DIR/$dest_name"

  if [[ ! -f "$src" ]]; then
    echo "error: missing capture: $src" >&2
    exit 1
  fi

  # sips -z takes height then width.
  sips -z "$WEB_H" "$WEB_W" "$src" --out "$dest" >/dev/null
  echo "  ✓ $dest_name ← ${DEVICE_PREFIX}-${name}.png"
done

echo "Done. Commit marketing changes in: $WEB_ROOT"
