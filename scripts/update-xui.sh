#!/usr/bin/env bash
# Обновление 3X-UI через Docker-образ (не кнопка «Обновить панель» в UI).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Запустите от root: sudo $0"
  exit 1
fi

if [[ ! -f .env ]]; then
  echo "Нет .env — скопируйте: cp .env.example .env" >&2
  exit 1
fi

# shellcheck source=/dev/null
source .env

XUI_VERSION="${XUI_VERSION:-3.4.1}"

echo "=== Обновление 3X-UI → ${XUI_VERSION} (образ ghcr.io/mhsanaei/3x-ui) ==="
echo "Данные панели в ${DATA_DIR:-/var/lib/afsun-proxy}/x-ui/db — не затрагиваются."
echo ""

docker compose pull x-ui
docker compose up -d x-ui
sleep 3

VER="$(docker exec afsun-x-ui /app/x-ui -v 2>/dev/null || true)"
echo ""
echo "Готово. Версия в контейнере: ${VER:-unknown}"
echo "Кнопка «Обновить панель» в UI для Docker не работает — используйте этот скрипт."
