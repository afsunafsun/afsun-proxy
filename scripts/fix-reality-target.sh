#!/usr/bin/env bash
# Синхронизирует realitySettings.target с dest (3X-UI 3.4.0 показывает «Цель» из target).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/.env" 2>/dev/null || true
# shellcheck source=lib/xui-api-token.sh
source "$ROOT/scripts/lib/xui-api-token.sh"

XUI_PORT="${XUI_PORT:-2053}"
REALITY_TARGET="${REALITY_TARGET:-${REALITY_DEST:-www.yahoo.com:443}}"

TOKEN="$(xui_api_token)"
WEB_BASE="$(xui_web_base)"
WEB_BASE="${WEB_BASE:-/panel/}"

if [[ -z "$TOKEN" ]]; then
  echo "Не удалось получить API-токен" >&2
  exit 1
fi

OUT="$(mktemp)"
python3 <<PY >"$OUT"
import json, urllib.request, sys

base = f"http://127.0.0.1:${XUI_PORT}{'${WEB_BASE}'.rstrip('/')}"
token = """${TOKEN}"""
default_target = "${REALITY_TARGET}"

def api(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        base + path, data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "X-Requested-With": "XMLHttpRequest",
        },
        method=method,
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)

def normalize_rs(rs):
    target = (rs.get("target") or rs.get("dest") or default_target).strip()
    if not target:
        return False
    changed = rs.get("target") != target or rs.get("dest") != target
    rs["target"] = target
    rs["dest"] = target
    return changed

updated = 0
for ib in api("GET", "/panel/api/inbounds/list")["obj"]:
    if ib.get("protocol") != "vless":
        continue
    if ib.get("streamSettings", {}).get("security") != "reality":
        continue
    rs = ib["streamSettings"].setdefault("realitySettings", {})
    if not normalize_rs(rs):
        continue
    r = api("POST", f"/panel/api/inbounds/update/{ib['id']}", ib)
    if not r.get("success"):
        raise SystemExit(f"Update inbound {ib['id']} failed: {r}")
    print(f"  inbound {ib['id']} port {ib['port']}: target={rs['target']}")
    updated += 1

if updated:
    print(f"Обновлено {updated} inbound(s)")
else:
    print("Цель (target) уже задана у всех Reality inbound'ов")
PY
cat "$OUT"
NEED_RESTART=0
grep -q '^  inbound' "$OUT" && NEED_RESTART=1
rm -f "$OUT"

if [[ "$NEED_RESTART" == 1 ]]; then
  docker compose -f "$ROOT/docker-compose.yml" restart x-ui >/dev/null
  sleep 3
  echo "Xray перезапущен."
fi
