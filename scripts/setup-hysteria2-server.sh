#!/usr/bin/env bash
# Официальный Hysteria2-сервер (не Xray inbound) с Let's Encrypt от Caddy.
# Xray HY2 inbound несовместим с Streisand/Hiddify/Shadowrocket (GitHub #5921).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/.env"
# shellcheck source=lib/xui-api-token.sh
source "$ROOT/scripts/lib/xui-api-token.sh"

XUI_PORT="${XUI_PORT:-2053}"
HY2_PORT="${HYSTERIA2_PORT:-8444}"
DATA_DIR="${DATA_DIR:-/var/lib/afsun-proxy}"
PROXY_DOMAIN="${PROXY_DOMAIN:-proxy.example.com}"
HY2_BIN="${DATA_DIR}/bin/hysteria2"
HY2_CFG="${DATA_DIR}/hysteria/server.yaml"
CADDY_CERT="${DATA_DIR}/caddy/data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${PROXY_DOMAIN}/${PROXY_DOMAIN}.crt"
CADDY_KEY="${DATA_DIR}/caddy/data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${PROXY_DOMAIN}/${PROXY_DOMAIN}.key"

TOKEN="$(xui_api_token)"
WEB_BASE="$(xui_web_base)"
WEB_BASE="${WEB_BASE:-/panel/}"

if [[ -z "$TOKEN" ]]; then
  echo "Не удалось получить API-тoken" >&2
  exit 1
fi

if [[ ! -f "$CADDY_CERT" || ! -f "$CADDY_KEY" ]]; then
  echo "Сертификат Caddy не найден: $CADDY_CERT" >&2
  exit 1
fi

mkdir -p "${DATA_DIR}/bin" "${DATA_DIR}/hysteria"

if [[ ! -x "$HY2_BIN" ]]; then
  echo "Скачивание hysteria2…"
  curl -fsSL "https://github.com/apernet/hysteria/releases/download/app/v2.6.2/hysteria-linux-amd64" \
    -o "$HY2_BIN"
  chmod +x "$HY2_BIN"
fi

AUTH="$(python3 -c "
import sqlite3
db=sqlite3.connect('${DATA_DIR}/x-ui/db/x-ui.db')
print(db.execute(\"SELECT auth FROM clients WHERE enable=1 LIMIT 1\").fetchone()[0])
")"

cat > "$HY2_CFG" <<EOF
listen: :${HY2_PORT}
tls:
  cert: ${CADDY_CERT}
  key: ${CADDY_KEY}
auth:
  type: password
  password: ${AUTH}
outbounds:
  - name: default
    type: direct
    direct:
      mode: 4
resolver:
  type: udp
  udp:
    addr: 1.1.1.1:53
  timeout: 4s
sniff:
  enable: true
  timeout: 2s
  rewriteDomain: true
EOF
chmod 600 "$HY2_CFG"

python3 <<PY
import json, sqlite3, time, urllib.parse, urllib.request

base = f"http://127.0.0.1:${XUI_PORT}{'${WEB_BASE}'.rstrip('/')}"
token = """${TOKEN}"""
hy_port = int("${HY2_PORT}")
domain = "${PROXY_DOMAIN}"
auth = """${AUTH}"""
db_path = "${DATA_DIR}/x-ui/db/x-ui.db"

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

# Отключить Xray HY2 inbound — освободить порт и убрать несовместимую строку из подписки
for ib in api("GET", "/panel/api/inbounds/list")["obj"]:
    if ib.get("protocol") == "hysteria" and ib.get("port") == hy_port:
        ib["enable"] = False
        r = api("POST", f"/panel/api/inbounds/update/{ib['id']}", ib)
        if not r.get("success"):
            raise SystemExit(f"Disable xray hysteria failed: {r}")
        print(f"Xray HY2 inbound id={ib['id']} отключён")

db = sqlite3.connect(db_path)
client_id = db.execute("SELECT id FROM clients WHERE enable=1 LIMIT 1").fetchone()[0]
hy2_uri = (
    f"hysteria2://{urllib.parse.quote(auth, safe='')}@{domain}:{hy_port}"
    f"?security=tls&sni={domain}#Hysteria2%20{hy_port}"
)
existing = db.execute(
    "SELECT id FROM client_external_links WHERE client_id=? AND kind='uri'", (client_id,)
).fetchone()
now = int(time.time() * 1000)
if existing:
    db.execute("UPDATE client_external_links SET value=?, remark=? WHERE id=?",
               (hy2_uri, f"Hysteria2 {hy_port}", existing[0]))
else:
    db.execute(
        "INSERT INTO client_external_links (client_id, kind, value, remark, sort_index, created_at) VALUES (?,?,?,?,?,?)",
        (client_id, "uri", hy2_uri, f"Hysteria2 {hy_port}", 0, now),
    )
db.commit()
print(f"External link: {hy2_uri[:60]}…")
PY

cat > /etc/systemd/system/afsun-hysteria2.service <<EOF
[Unit]
Description=afsun-proxy Hysteria2 (official)
After=network.target docker.service
Wants=docker.service

[Service]
Type=simple
ExecStart=${HY2_BIN} server -c ${HY2_CFG}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable afsun-hysteria2
systemctl restart afsun-hysteria2
sleep 2

docker compose -f "$ROOT/docker-compose.yml" restart x-ui
sleep 3

if systemctl is-active --quiet afsun-hysteria2 && ss -ulnp | grep -q ":${HY2_PORT} "; then
  bash "$ROOT/scripts/sync-ufw-inbounds.sh"
  echo "Hysteria2 official: active на UDP ${HY2_PORT}, LE cert ${PROXY_DOMAIN}"
  echo "Обновите подписку в приложении."
else
  echo "ОШИБКА: hysteria2 не слушает ${HY2_PORT}" >&2
  journalctl -u afsun-hysteria2 -n 20 --no-pager >&2
  exit 1
fi
