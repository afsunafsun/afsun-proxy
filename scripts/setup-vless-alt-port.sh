#!/usr/bin/env bash
# VLESS Reality на альтернативном TCP-порту (запасной inbound).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/.env"
# shellcheck source=lib/xui-api-token.sh
source "$ROOT/scripts/lib/xui-api-token.sh"

XUI_PORT="${XUI_PORT:-2053}"
ALT_PORT="${VLESS_ALT_PORT:-8445}"
DATA_DIR="${DATA_DIR:-/var/lib/afsun-proxy}"

TOKEN="$(xui_api_token)"
WEB_BASE="$(xui_web_base)"
WEB_BASE="${WEB_BASE:-/panel/}"

if [[ -z "$TOKEN" ]]; then
  echo "Не удалось получить API-токен панели" >&2
  exit 1
fi

python3 <<PY
import json, sqlite3, urllib.parse, urllib.request, sys

base = f"http://127.0.0.1:${XUI_PORT}{'${WEB_BASE}'.rstrip('/')}"
token = """${TOKEN}"""
alt_port = int("${ALT_PORT}")
db_path = "${DATA_DIR}/x-ui/db/x-ui.db"

def api(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        base + path,
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "X-Requested-With": "XMLHttpRequest",
        },
        method=method,
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)

for ib in api("GET", "/panel/api/inbounds/list")["obj"]:
    if ib.get("protocol") == "vless" and ib.get("port") == alt_port:
        print(f"VLESS alt уже есть: id={ib['id']} port={alt_port}")
        sys.exit(0)

db = sqlite3.connect(db_path)
row = db.execute(
    "SELECT id, stream_settings FROM inbounds WHERE port=443 AND protocol='vless' LIMIT 1"
).fetchone()
if not row:
    raise SystemExit("VLESS inbound на 443 не найден")
src_id, stream_raw = row
stream = json.loads(stream_raw)

inbound = {
    "enable": True,
    "remark": f"VLESS Reality {alt_port}",
    "listen": "",
    "port": alt_port,
    "protocol": "vless",
    "settings": {"clients": [], "decryption": "none", "fallbacks": []},
    "streamSettings": stream,
    "sniffing": {
        "enabled": True,
        "destOverride": ["http", "tls", "quic"],
        "metadataOnly": False,
        "routeOnly": False,
    },
}
resp = api("POST", "/panel/api/inbounds/add", inbound)
if not resp.get("success"):
    raise SystemExit(f"Add inbound failed: {resp}")
alt_id = resp["obj"]["id"]
print(f"Создан VLESS alt inbound id={alt_id} port={alt_port}")

clients = db.execute(
    """
    SELECT c.email, c.sub_id, c.uuid, c.auth
    FROM clients c
    JOIN client_inbounds ci ON ci.client_id = c.id
    WHERE ci.inbound_id = ? AND c.enable = 1
    """,
    (src_id,),
).fetchall()
for email, sub_id, uuid, auth in clients:
    att = api("POST", f"/panel/api/clients/{urllib.parse.quote(email, safe='@.')}/attach", {
        "inboundIds": [alt_id],
    })
    if not att.get("success"):
        raise SystemExit(f"Attach {email} failed: {att}")
    print(f"  + {email} → VLESS {alt_port}")

print("Перезапуск Xray…")
PY

docker compose -f "$ROOT/docker-compose.yml" restart x-ui
sleep 4
bash "$ROOT/scripts/sync-ufw-inbounds.sh"
echo "Готово. Обновите подписку — появится VLESS на порту ${ALT_PORT}."
