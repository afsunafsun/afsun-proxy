#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="/opt/afsun-proxy"
DATA_DIR="/var/lib/afsun-proxy"
REPO_URL="https://github.com/afsunafsun/afsun-proxy.git"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Запустите от root: sudo $0"
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Установка Docker..."
  curl -fsSL https://get.docker.com | sh
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose не найден"
  exit 1
fi

if [[ ! -d "$INSTALL_DIR/.git" ]]; then
  echo "Клонирование репозитория в $INSTALL_DIR"
  mkdir -p /opt
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

mkdir -p "${DATA_DIR}/x-ui/db" "${DATA_DIR}/x-ui/cert"
mkdir -p "${DATA_DIR}/caddy/data" "${DATA_DIR}/caddy/config"

if [[ ! -f .env ]]; then
  bash scripts/generate-env.sh
fi

if ! grep -q "^DATA_DIR=" .env; then
  echo "DATA_DIR=${DATA_DIR}" >> .env
fi

PROXY_DOMAIN=$(grep '^PROXY_DOMAIN=' .env 2>/dev/null | cut -d= -f2- || true)
if [[ -z "$PROXY_DOMAIN" || "$PROXY_DOMAIN" == "proxy.example.com" ]]; then
  echo ""
  echo "⚠️  Отредактируйте PROXY_DOMAIN и CADDY_EMAIL в .env перед продакшеном:"
  echo "    nano ${INSTALL_DIR}/.env"
  echo ""
fi

if [[ ! -f config/caddy/Caddyfile ]]; then
  cp config/caddy/Caddyfile.example config/caddy/Caddyfile
  echo "Создан config/caddy/Caddyfile из шаблона"
fi

echo "Загрузка geofiles (нужен интернет)..."
bash scripts/setup-geofiles.sh

sysctl -w net.ipv4.ip_forward=1
if ! grep -q 'net.ipv4.ip_forward=1' /etc/sysctl.conf 2>/dev/null; then
  echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
fi

echo "Запуск стека..."
docker compose pull
docker compose up -d

echo ""
echo "=== afsun-proxy v2 (3X-UI) запущен ==="
echo "Данные: ${DATA_DIR}"
echo ""
PROXY_DOMAIN=$(grep '^PROXY_DOMAIN=' .env 2>/dev/null | cut -d= -f2- || echo "proxy.example.com")
echo "Панель (после настройки 3X-UI): https://${PROXY_DOMAIN}:8443/<webBasePath>/"
echo ""
echo "Дальше:"
echo "  sudo bash scripts/bootstrap.sh   # панель + VLESS + подписка"
echo "  docs/OPERATIONS.md"
