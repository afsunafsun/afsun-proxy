#!/usr/bin/env bash
# VLESS + Reality на :443 и первый клиент — через API 3X-UI (идемпотентно).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/.env"
# shellcheck source=lib/xui-api-token.sh
source "$ROOT/scripts/lib/xui-api-token.sh"
# shellcheck source=lib/reality-keys.sh
source "$ROOT/scripts/lib/reality-keys.sh"

XUI_PORT="${XUI_PORT:-2053}"
VLESS_PORT="${VLESS_PORT:-443}"
DATA_DIR="${DATA_DIR:-/var/lib/afsun-proxy}"
PROXY_DOMAIN="${PROXY_DOMAIN:-proxy.example.com}"
CLIENT_EMAIL="${CLIENT_EMAIL:-admin@${PROXY_DOMAIN}}"
REALITY_TARGET="${REALITY_TARGET:-${REALITY_DEST:-www.yahoo.com:443}}"
REALITY_SNI="${REALITY_SNI:-www.yahoo.com,yahoo.com}"
REALITY_FP="${REALITY_FP:-firefox}"

TOKEN="$(xui_api_token)"
WEB_BASE="$(xui_web_base)"
WEB_BASE="${WEB_BASE:-/panel/}"

if [[ -z "$TOKEN" ]]; then
  echo "Не удалось получить API-токен. Сначала: sudo bash scripts/setup-xui.sh" >&2
  exit 1
fi

KEYPAIR="$(xui_reality_keypair)" || {
  echo "Не удалось сгенерировать ключи Reality (xray x25519)" >&2
  exit 1
}
REALITY_PRIVATE="${KEYPAIR%%|*}"
REALITY_PUBLIC="${KEYPAIR#*|}"

OUT="$(mktemp)"
python3 <<PY >"$OUT"
import json, secrets, sys, urllib.parse, urllib.request, uuid

base = f"http://127.0.0.1:${XUI_PORT}{'${WEB_BASE}'.rstrip('/')}"
token = """${TOKEN}"""
port = int("${VLESS_PORT}")
email = """${CLIENT_EMAIL}"""
domain = """${PROXY_DOMAIN}"""
target = "${REALITY_TARGET}"
dest = target
snis = [s.strip() for s in "${REALITY_SNI}".split(",") if s.strip()]
fp = "${REALITY_FP}"
private_key = """${REALITY_PRIVATE}"""
public_key = """${REALITY_PUBLIC}"""

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

def gen_short_ids():
    ids = set()
    while len(ids) < 8:
        n = secrets.choice([2, 4, 6, 8, 10, 12, 16])
        ids.add(secrets.token_hex(8)[:n])
    return sorted(ids, key=len)

def new_client():
    return {
        "id": str(uuid.uuid4()),
        "email": email,
        "enable": True,
        "flow": "xtls-rprx-vision",
        "subId": secrets.token_hex(8),
        "limitIp": 0,
        "totalGB": 0,
        "expiryTime": 0,
        "tgId": 0,
        "reset": 0,
    }

def stream_settings():
    return {
        "network": "tcp",
        "security": "reality",
        "externalProxy": [],
        "realitySettings": {
            "show": False,
            "xver": 0,
            "target": target,
            "dest": target,
            "serverNames": snis,
            "privateKey": private_key,
            "minClient": "",
            "maxClient": "",
            "maxTimediff": 0,
            "shortIds": gen_short_ids(),
            "settings": {
                "publicKey": public_key,
                "fingerprint": fp,
                "serverName": "",
                "spiderX": "/",
            },
        },
        "tcpSettings": {
            "acceptProxyProtocol": False,
            "header": {"type": "none"},
        },
    }

sniffing = {
    "enabled": True,
    "destOverride": ["http", "tls", "quic"],
    "metadataOnly": False,
    "routeOnly": False,
}

inbounds = api("GET", "/panel/api/inbounds/list")["obj"]
for ib in inbounds:
    if ib.get("protocol") != "vless" or ib.get("port") != port:
        continue
    clients = ib.get("settings", {}).get("clients", [])
    if clients:
        sub = clients[0].get("subId", "")
        print(f"VLESS Reality :{port} уже есть (inbound id={ib['id']})")
        if sub:
            print(f"SUBSCRIPTION=https://{domain}:8443/sub/{sub}")
        sys.exit(0)
    client = new_client()
    resp = api("POST", "/panel/api/inbounds/addClient", {
        "id": ib["id"],
        "settings": {"clients": [client]},
    })
    if not resp.get("success"):
        raise SystemExit(f"addClient failed: {resp}")
    print(f"Клиент добавлен к inbound id={ib['id']}")
    print(f"SUBSCRIPTION=https://{domain}:8443/sub/{client['subId']}")
    sys.exit(0)

client = new_client()
inbound = {
    "enable": True,
    "remark": f"VLESS Reality {port}",
    "listen": "",
    "port": port,
    "protocol": "vless",
    "settings": {
        "clients": [client],
        "decryption": "none",
        "fallbacks": [],
    },
    "streamSettings": stream_settings(),
    "sniffing": sniffing,
}
resp = api("POST", "/panel/api/inbounds/add", inbound)
if not resp.get("success"):
    raise SystemExit(f"Add inbound failed: {resp}")
ib_id = resp["obj"]["id"]
print(f"Создан VLESS Reality inbound id={ib_id} port={port}")
print(f"Клиент: {email}")
print(f"SUBSCRIPTION=https://{domain}:8443/sub/{client['subId']}")
PY
cat "$OUT"
NEED_RESTART=0
grep -qE '^(Создан |Клиент добавлен)' "$OUT" && NEED_RESTART=1
rm -f "$OUT"

if [[ "$NEED_RESTART" == 1 ]]; then
  docker compose -f "$ROOT/docker-compose.yml" restart x-ui >/dev/null
  sleep 4
  echo "Xray перезапущен."
  bash "$ROOT/scripts/sync-ufw-inbounds.sh"
fi
