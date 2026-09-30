#!/usr/bin/env bash
# =============================================================================
#  Cold backup of the whole stack state (./data) — consistent by construction.
#
#    scripts/backup.sh                → backups/graphrag-<UTC stamp>.tar.gz
#    scripts/backup.sh /mnt/backups   → that folder instead
#
#  Stops the containers for the duration of the archive (seconds to minutes
#  depending on the corpus), then starts them again. Restore: see README.
# =============================================================================
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
DEST="${1:-$ROOT/backups}"
mkdir -p "$DEST"
STAMP="$(date -u +%Y%m%d-%H%M%S)"
OUT="$DEST/graphrag-$STAMP.tar.gz"

[ -d data ] || { echo "ERROR: no ./data folder here — nothing to back up." >&2; exit 1; }

echo "==> Stopping the stack"
docker compose stop
trap 'echo "==> Starting the stack"; docker compose start' EXIT

echo "==> Archiving ./data and .env to $OUT"
tar -czf "$OUT" data .env
echo "    $(du -h "$OUT" | cut -f1) written."
