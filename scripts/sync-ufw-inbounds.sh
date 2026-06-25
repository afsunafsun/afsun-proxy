#!/usr/bin/env bash
# Открывает в UFW порты включённых inbound'ов из БД 3X-UI (+ official Hysteria2).
# Панель порты в файрволе не открывает — только этот скрипт или setup-ufw.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/.env" 2>/dev/null || true
DATA_DIR="${DATA_DIR:-/var/lib/afsun-proxy}"
HY2_PORT="${HYSTERIA2_PORT:-8444}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Запустите от root: sudo $0" >&2
  exit 1
fi

if ! command -v ufw >/dev/null 2>&1; then
  echo "ufw не установлен" >&2
  exit 1
fi

ufw_has_rule() {
  local port="$1" proto="$2"
  ufw status 2>/dev/null | grep -qE "^${port}/${proto}[[:space:]]"
}

ufw_allow_once() {
  local spec="$1" comment="${2:-afsun-proxy inbound}"
  local port="${spec%%/*}" proto="${spec#*/}"
  if ufw_has_rule "$port" "$proto"; then
    echo "  уже есть: ${spec}"
    return 0
  fi
  ufw allow "$spec" comment "$comment"
  echo "  + ${spec} (${comment})"
}

DB="${DATA_DIR}/x-ui/db/x-ui.db"
if [[ ! -f "$DB" ]]; then
  echo "БД 3X-UI не найдена: $DB" >&2
  exit 1
fi

echo "Синхронизация UFW с inbound'ами…"

while IFS=$'\t' read -r spec comment; do
  [[ -n "$spec" ]] || continue
  ufw_allow_once "$spec" "$comment"
done < <(DATA_DIR="$DATA_DIR" python3 <<'PY'
import os, sqlite3

data = os.environ["DATA_DIR"]
db = sqlite3.connect(f"{data}/x-ui/db/x-ui.db")
skip_ports = {2053, 2096}
udp_only = {"hysteria", "hysteria2", "wireguard"}
both = {"socks", "mixed"}
seen = set()

for port, protocol, remark, enable in db.execute(
    "SELECT port, protocol, remark, enable FROM inbounds WHERE enable=1"
):
    if not port or port in skip_ports:
        continue
    proto = (protocol or "").lower()
    label = (remark or proto or "inbound").replace('"', "'")[:40]
    comment = f"inbound: {label}:{port}"

    if proto in both:
        for p in ("tcp", "udp"):
            key = (port, p)
            if key not in seen:
                seen.add(key)
                print(f"{port}/{p}\t{comment}")
    elif proto in udp_only:
        key = (port, "udp")
        if key not in seen:
            seen.add(key)
            print(f"{port}/udp\t{comment}")
    else:
        key = (port, "tcp")
        if key not in seen:
            seen.add(key)
            print(f"{port}/tcp\t{comment}")
PY
)

if systemctl is-active --quiet afsun-hysteria2 2>/dev/null; then
  ufw_allow_once "${HY2_PORT}/udp" "Hysteria2 official"
fi

echo "Готово. ufw status:"
ufw status | grep -E '^(Status|[0-9]+)' || ufw status
