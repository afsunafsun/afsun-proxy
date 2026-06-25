#!/usr/bin/env bash
# API-токен панели (docker exec) — без логина/пароля и без файлов с кредами.
xui_api_token() {
  docker exec afsun-x-ui /app/x-ui setting -getApiToken true 2>/dev/null \
    | awk -F': ' '/^apiToken:/{print $2; exit}'
}

xui_web_base() {
  docker exec afsun-x-ui /app/x-ui setting -show true 2>/dev/null \
    | awk -F': ' '/^webBasePath:/{print $2; exit}'
}
