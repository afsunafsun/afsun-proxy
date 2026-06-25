#!/usr/bin/env bash
set -euo pipefail
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8443/tcp
# Опционально (см. docs/OPERATIONS.md):
# ufw allow 10808/tcp && ufw allow 10808/udp   # SOCKS
# ufw allow 8444/udp                            # Hysteria2 (official)
# ufw allow 2087/tcp                            # VLESS alt port
ufw --force enable
ufw status
