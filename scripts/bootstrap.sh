#!/usr/bin/env bash
# Полная первичная настройка: панель → VLESS Reality → подписка.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Запустите от root: sudo $0"
  exit 1
fi

if [[ ! -f .env ]]; then
  echo "Сначала: cp .env.example .env && nano .env" >&2
  exit 1
fi

# shellcheck source=/dev/null
source .env

PROXY_DOMAIN="${PROXY_DOMAIN:-}"
if [[ -z "$PROXY_DOMAIN" || "$PROXY_DOMAIN" == "proxy.example.com" ]]; then
  echo "Укажите PROXY_DOMAIN в .env (A-запись на IP сервера)" >&2
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -qx 'afsun-x-ui'; then
  echo "Контейнер afsun-x-ui не запущен. Сначала: sudo bash scripts/install.sh" >&2
  exit 1
fi

echo "=== bootstrap: настройка панели ==="
bash scripts/setup-xui.sh | tee /tmp/afsun-setup-xui.out

echo ""
echo "=== bootstrap: UFW ==="
bash scripts/setup-ufw.sh

echo ""
echo "=== bootstrap: VLESS Reality :443 ==="
bash scripts/setup-vless-inbound.sh | tee /tmp/afsun-vless.out

echo ""
echo "=== bootstrap: Цель (target) Reality ==="
bash scripts/fix-reality-target.sh

echo ""
echo "=== bootstrap: синхронизация UFW с inbound'ами ==="
bash scripts/sync-ufw-inbounds.sh

echo ""
echo "=== bootstrap: подписка и geofiles ==="
bash scripts/finish-panel-setup.sh

SUB_URL="$(grep -o 'SUBSCRIPTION=https://[^[:space:]]*' /tmp/afsun-vless.out 2>/dev/null | head -1 | cut -d= -f2- || true)"
PANEL_URL="$(grep -o 'https://[^[:space:]]*' /tmp/afsun-setup-xui.out 2>/dev/null | grep ':8443' | head -1 || true)"
PANEL_PASS="$(grep '^Пароль' /tmp/afsun-setup-xui.out 2>/dev/null | sed 's/^Пароль (сохраните сами): //' || true)"

echo ""
echo "============================================"
echo "  VPN готов"
echo "============================================"
[[ -n "$PANEL_URL" ]] && echo "Панель:     $PANEL_URL"
[[ -n "$PANEL_PASS" ]] && echo "Пароль:     $PANEL_PASS  (сохраните)"
[[ -n "$SUB_URL" ]] && echo "Подписка:   $SUB_URL"
echo ""
echo "На телефоне: v2rayNG / Hiddify / Streisand → импорт подписки"
echo "Опционально: sudo bash scripts/setup-hysteria2-server.sh"
echo "Справка:     docs/OPERATIONS.md"
echo "============================================"
