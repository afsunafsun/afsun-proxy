#!/usr/bin/env bash
# Включает HTTPS-подписку через Caddy (настройки панели через API-токен).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/.env"
# shellcheck source=lib/xui-api-token.sh
source "$ROOT/scripts/lib/xui-api-token.sh"

XUI_PORT="${XUI_PORT:-2053}"
PROXY_DOMAIN="${PROXY_DOMAIN:-proxy.example.com}"
DATA_DIR="${DATA_DIR:-/var/lib/afsun-proxy}"

TOKEN="$(xui_api_token)"
WEB_BASE="$(xui_web_base)"
WEB_BASE="${WEB_BASE:-/panel/}"

if [[ -z "$TOKEN" ]]; then
  echo "Не удалось получить API-токен панели (docker exec afsun-x-ui … -getApiToken)" >&2
  exit 1
fi

python3 <<PY
import json, os, sys, urllib.request

base = f"http://127.0.0.1:${XUI_PORT}{'${WEB_BASE}'.rstrip('/')}"
token = """${TOKEN}"""
domain = "${PROXY_DOMAIN}"

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

settings = api("POST", "/panel/api/setting/all", {})["obj"]
settings.update({
    "subEnable": True,
    "subListen": "127.0.0.1",
    "subPort": 2096,
    "subPath": "/sub/",
    "subJsonPath": "/json/",
    "subDomain": domain,
    "subTitle": "afsun-proxy",
    "subURI": f"https://{domain}:8443/sub/",
    "subJsonURI": f"https://{domain}:8443/json/",
    "subEncrypt": True,
    "subShowInfo": True,
})
resp = api("POST", "/panel/api/setting/update", settings)
if not resp.get("success"):
    print("Settings update failed:", resp, file=sys.stderr)
    sys.exit(1)
print("Подписка включена.")
PY

SUB_ID="$(DATA_DIR="${DATA_DIR}" python3 <<'PY'
import sqlite3, json, os
data = os.environ["DATA_DIR"]
db = sqlite3.connect(f"{data}/x-ui/db/x-ui.db")
row = db.execute("SELECT settings FROM inbounds WHERE protocol='vless' AND enable=1 LIMIT 1").fetchone()
if not row:
    raise SystemExit(0)
clients = json.loads(row[0]).get("clients", [])
print(clients[0].get("subId", "") if clients else "")
PY
)"

if [[ -n "$SUB_ID" ]]; then
  echo ""
  echo "Ссылка подписки (обновить в v2rayNG / Hiddify):"
  echo "  https://${PROXY_DOMAIN}:8443/sub/${SUB_ID}"
  echo ""
  echo "На телефоне: удалить старый профиль → импортировать подписку заново."
else
  echo "VLESS inbound не найден — создайте клиента в панели и повторите."
fi
