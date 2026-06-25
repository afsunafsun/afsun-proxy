#!/usr/bin/env bash
# Скачивает community geosite/geoip для Xray (runetfreedom).
# Файлы монтируются в /app/bin/ контейнера 3X-UI — см. docker-compose.yml
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/.env" 2>/dev/null || true
DATA_DIR="${DATA_DIR:-/var/lib/afsun-proxy}"
GEO_DIR="${DATA_DIR}/x-ui/geofiles"

GEOSITE_URL="${GEOSITE_RU_URL:-https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/release/geosite.dat}"
GEOIP_URL="${GEOIP_RU_BLOCKED_URL:-https://raw.githubusercontent.com/runetfreedom/russia-blocked-geoip/release/ru-blocked.dat}"

mkdir -p "$GEO_DIR"

download() {
  local url="$1" dest="$2"
  echo "→ $dest"
  curl -fsSL --retry 3 --retry-delay 2 -o "${dest}.tmp" "$url"
  mv "${dest}.tmp" "$dest"
}

download "$GEOSITE_URL" "$GEO_DIR/geosite_ru-rules.dat"
download "$GEOIP_URL" "$GEO_DIR/geoip_ru-blocked.dat"

ls -lh "$GEO_DIR"
echo "Готово. В панели: ext:geosite_ru-rules.dat:ru-blocked, ext:geoip_ru-blocked.dat:ru-blocked"
