#!/usr/bin/env bash
# Первичная настройка 3X-UI: localhost, пароль, webBasePath (идемпотентно).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROXY_DOMAIN=$(grep '^PROXY_DOMAIN=' "$ROOT/.env" 2>/dev/null | cut -d= -f2- || echo "proxy.example.com")

if docker exec afsun-x-ui /app/x-ui setting -getListen true 2>/dev/null | grep -q '127.0.0.1'; then
  BASE="$(docker exec afsun-x-ui /app/x-ui setting -show true 2>/dev/null | awk -F': ' '/^webBasePath:/{print $2; exit}')"
  echo "3X-UI уже настроен (listen 127.0.0.1)."
  echo "Панель: https://${PROXY_DOMAIN}:8443${BASE}"
  echo "Дальнейшие скрипты используют API-токен панели, не пароль."
  exit 0
fi

USER="${XUI_ADMIN_USER:-admin}"
PASS="${XUI_ADMIN_PASS:-$(openssl rand -hex 12)}"
BASE="${XUI_WEB_BASE:-/panel-$(openssl rand -hex 4)/}"

docker exec afsun-x-ui /app/x-ui setting -listenIP 127.0.0.1
docker exec afsun-x-ui /app/x-ui setting -username "$USER" -password "$PASS"
docker exec afsun-x-ui /app/x-ui setting -webBasePath "$BASE"
docker restart afsun-x-ui >/dev/null
sleep 3

echo "Панель: https://${PROXY_DOMAIN}:8443${BASE}"
echo "Логин: $USER"
echo "Пароль (сохраните сами): $PASS"
echo ""
echo "Дальнейшие скрипты используют API-токен панели, не пароль."
