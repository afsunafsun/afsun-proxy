#!/usr/bin/env bash
# Смена Reality dest/SNI и fingerprint (сигнатура TLS, не порт).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/.env"
# shellcheck source=lib/xui-api-token.sh
source "$ROOT/scripts/lib/xui-api-token.sh"

XUI_PORT="${XUI_PORT:-2053}"
REALITY_TARGET="${REALITY_TARGET:-${REALITY_DEST:-www.yahoo.com:443}}"
REALITY_SNI="${REALITY_SNI:-www.yahoo.com,yahoo.com}"
REALITY_FP="${REALITY_FP:-firefox}"

TOKEN="$(xui_api_token)"
WEB_BASE="$(xui_web_base)"
WEB_BASE="${WEB_BASE:-/panel/}"

python3 <<PY
import json, urllib.request, sys

base = f"http://127.0.0.1:${XUI_PORT}{'${WEB_BASE}'.rstrip('/')}"
token = """${TOKEN}"""
dest = "${REALITY_TARGET}"
snis = [s.strip() for s in "${REALITY_SNI}".split(",") if s.strip()]
fp = "${REALITY_FP}"

def api(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        base + path, data=data,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json",
                 "X-Requested-With": "XMLHttpRequest"},
        method=method,
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)

updated = 0
for ib in api("GET", "/panel/api/inbounds/list")["obj"]:
    if ib.get("protocol") != "vless" or ib.get("streamSettings", {}).get("security") != "reality":
        continue
    rs = ib["streamSettings"].setdefault("realitySettings", {})
    rs["target"] = dest
    rs["dest"] = dest
    rs["serverNames"] = snis
    rs.setdefault("settings", {})["fingerprint"] = fp
    r = api("POST", f"/panel/api/inbounds/update/{ib['id']}", ib)
    if not r.get("success"):
        raise SystemExit(f"Update inbound {ib['id']} failed: {r}")
    print(f"  inbound {ib['id']} port {ib['port']}: target={dest} fp={fp}")
    updated += 1

if not updated:
    raise SystemExit("VLESS Reality inbound не найден")
print(f"Обновлено {updated} inbound(s)")
PY

docker compose -f "$ROOT/docker-compose.yml" restart x-ui
sleep 3
echo "Готово. Обновите подписку."
