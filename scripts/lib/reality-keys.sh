#!/usr/bin/env bash
# Генерация пары ключей Reality через Xray из контейнера 3X-UI.
xui_reality_keypair() {
  local out private public
  out="$(docker exec afsun-x-ui /app/bin/xray-linux-amd64 x25519 2>/dev/null)" || return 1
  private="$(printf '%s\n' "$out" | awk -F': ' '/^PrivateKey:/{print $2; exit}')"
  public="$(printf '%s\n' "$out" | awk -F': ' '/^Password \(PublicKey\):/{print $2; exit}')"
  if [[ -z "$private" || -z "$public" ]]; then
    return 1
  fi
  printf '%s|%s\n' "$private" "$public"
}
