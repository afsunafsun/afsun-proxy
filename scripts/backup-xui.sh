#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${DATA_DIR:-/var/lib/afsun-proxy}"
OUT="/root/backup-xui-$(date +%F-%H%M).tar.gz"

tar czf "$OUT" \
  "${DATA_DIR}/x-ui" \
  /opt/afsun-proxy/.env 2>/dev/null || true

echo "Бэкап: $OUT"
