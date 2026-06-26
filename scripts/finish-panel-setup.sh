#!/usr/bin/env bash
# Финишная настройка панели: geofiles, подписка, перезапуск стека.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bash scripts/setup-geofiles.sh
bash scripts/configure-xui-subscription.sh
bash scripts/ensure-xray-metrics.sh

docker compose up -d
sleep 3
docker exec afsun-caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || docker compose restart caddy

echo ""
echo "Проверка портов:"
ss -tlnp | grep -E ':(443|2096|10808|8443)\b' || true

SUB_ID="$(DATA_DIR="${DATA_DIR:-/var/lib/afsun-proxy}" python3 <<'PY'
import sqlite3, json, os
data = os.environ.get("DATA_DIR", "/var/lib/afsun-proxy")
db = sqlite3.connect(f"{data}/x-ui/db/x-ui.db")
row = db.execute("SELECT settings FROM inbounds WHERE protocol='vless' AND enable=1 LIMIT 1").fetchone()
if row:
    clients = json.loads(row[0]).get("clients", [])
    if clients:
        print(clients[0].get("subId", ""))
PY
)"

DOMAIN="$(grep '^PROXY_DOMAIN=' .env | cut -d= -f2-)"
if [[ -n "$SUB_ID" && -n "$DOMAIN" ]]; then
  echo ""
  echo "Подписка: https://${DOMAIN}:8443/sub/${SUB_ID}"
fi
