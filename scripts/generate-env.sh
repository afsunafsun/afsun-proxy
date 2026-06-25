#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT}/.env"

cp "${ROOT}/.env.example" "$ENV_FILE"
chmod 600 "$ENV_FILE"

DATA_DIR="/var/lib/afsun-proxy"
if ! grep -q "^DATA_DIR=" "$ENV_FILE"; then
  echo "DATA_DIR=${DATA_DIR}" >> "$ENV_FILE"
fi

echo "Создан ${ENV_FILE} — при необходимости отредактируйте PROXY_DOMAIN"
