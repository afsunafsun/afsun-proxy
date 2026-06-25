#!/usr/bin/env bash
# Одноразовый снос Marzban v1 (если остались контейнеры/volumes)
set -euo pipefail

cd /opt/afsun-proxy 2>/dev/null && docker compose --profile socks down -v 2>/dev/null || true
docker rm -f afsun-marzban afsun-mariadb afsun-caddy afsun-marzban-hooks afsun-socks-webhook 2>/dev/null || true
echo "v1 контейнеры удалены. Данные Marzban: rm -rf /var/lib/afsun-proxy/mysql /var/lib/afsun-proxy/marzban"
