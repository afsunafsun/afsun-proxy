#!/usr/bin/env bash
# Metrics + Observatory в шаблоне Xray (графики и health-check в панели 3X-UI).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/.env"
# shellcheck source=lib/xui-api-token.sh
source "$ROOT/scripts/lib/xui-api-token.sh"

XUI_PORT="${XUI_PORT:-2053}"
XRAY_METRICS_LISTEN="${XRAY_METRICS_LISTEN:-127.0.0.1:11111}"
XRAY_METRICS_TAG="${XRAY_METRICS_TAG:-metrics_out}"
XRAY_OBSERVATORY_PROBE_URL="${XRAY_OBSERVATORY_PROBE_URL:-https://www.google.com/generate_204}"
XRAY_OBSERVATORY_PROBE_INTERVAL="${XRAY_OBSERVATORY_PROBE_INTERVAL:-1m}"
# Опционально: явный список тегов через запятую (иначе — авто из outbounds)
XRAY_OBSERVATORY_TAGS="${XRAY_OBSERVATORY_TAGS:-}"

TOKEN="$(xui_api_token)"
WEB_BASE="$(xui_web_base)"
WEB_BASE="${WEB_BASE:-/panel/}"

if [[ -z "$TOKEN" ]]; then
  echo "Не удалось получить API-токен панели (docker exec afsun-x-ui … -getApiToken)" >&2
  exit 1
fi

RESULT="$(python3 <<PY
import json, sys, urllib.parse, urllib.request

base = f"http://127.0.0.1:${XUI_PORT}{'${WEB_BASE}'.rstrip('/')}"
token = """${TOKEN}"""
metrics_listen = "${XRAY_METRICS_LISTEN}"
metrics_tag = "${XRAY_METRICS_TAG}"
obs_probe_url = "${XRAY_OBSERVATORY_PROBE_URL}"
obs_probe_interval = "${XRAY_OBSERVATORY_PROBE_INTERVAL}"
obs_tags_override = "${XRAY_OBSERVATORY_TAGS}"

PROBE_PROTOCOLS = {
    "freedom", "vmess", "vless", "trojan", "shadowsocks", "socks", "http", "wireguard", "hysteria",
}
SKIP_TAGS = {"blocked", "blackhole", "dns", "loopback"}


def api_json(path, body=None):
    data = json.dumps(body or {}).encode()
    req = urllib.request.Request(
        base + path, data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "X-Requested-With": "XMLHttpRequest",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def api_form(path, fields):
    data = urllib.parse.urlencode(fields).encode()
    req = urllib.request.Request(
        base + path, data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/x-www-form-urlencoded",
            "X-Requested-With": "XMLHttpRequest",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def desired_obs_tags(outbounds):
    if obs_tags_override.strip():
        return [t.strip() for t in obs_tags_override.split(",") if t.strip()]
    tags = []
    for ob in outbounds:
        proto = ob.get("protocol")
        tag = ob.get("tag")
        if proto in PROBE_PROTOCOLS and tag and tag not in SKIP_TAGS:
            tags.append(tag)
    if tags:
        return tags
    for ob in outbounds:
        if ob.get("tag") == "direct":
            return ["direct"]
    return ["direct"]


def observatory_ok(current, desired_tags):
    if not isinstance(current, dict):
        return False
    sel = current.get("subjectSelector") or []
    if sorted(sel) != sorted(desired_tags):
        return False
    if current.get("probeURL") != obs_probe_url:
        return False
    if current.get("probeInterval") != obs_probe_interval:
        return False
    return True


wrap = json.loads(api_json("/panel/api/xray/")["obj"])
xs = wrap["xraySetting"]
changed = []

metrics = xs.get("metrics") or {}
if metrics.get("listen") != metrics_listen or metrics.get("tag") != metrics_tag:
    xs["metrics"] = {"listen": metrics_listen, "tag": metrics_tag}
    changed.append("metrics")

desired_tags = desired_obs_tags(xs.get("outbounds") or [])
if not observatory_ok(xs.get("observatory"), desired_tags):
    xs["observatory"] = {
        "subjectSelector": desired_tags,
        "probeURL": obs_probe_url,
        "probeInterval": obs_probe_interval,
        "enableConcurrency": True,
    }
    changed.append("observatory")

if not changed:
    print("skip")
    sys.exit(0)

resp = api_form("/panel/api/xray/update", {
    "xraySetting": json.dumps(xs),
    "outboundTestUrl": wrap.get("outboundTestUrl", "https://www.google.com/generate_204"),
})
if not resp.get("success"):
    print("Xray template update failed:", resp, file=sys.stderr)
    sys.exit(1)
print(",".join(changed))
PY
)"

if [[ "$RESULT" == "skip" ]]; then
  echo "Xray metrics и Observatory уже настроены."
  exit 0
fi

echo "Обновлено в шаблоне Xray: ${RESULT//,/, }"
docker compose -f "$ROOT/docker-compose.yml" restart x-ui
sleep 3
echo "Готово."
