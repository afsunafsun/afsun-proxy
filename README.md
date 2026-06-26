# afsun-proxy v2

[![Release](https://img.shields.io/github/v/release/afsunafsun/afsun-proxy)](https://github.com/afsunafsun/afsun-proxy/releases)

Open-source стек VPN/прокси: **3X-UI + Xray + Caddy** в Docker.

v2 — полный перезапуск без Marzban/MariaDB. Нативные **SOCKS**, **Hysteria2** (official), подписка для клиентов.

> **Disclaimer:** инструмент для развёртывания **собственного** прокси на **вашем** сервере. Ответственность за использование — на администраторе. См. [docs/DISCLAIMER.md](docs/DISCLAIMER.md) и [docs/ACCEPTABLE-USE.md](docs/ACCEPTABLE-USE.md).

## Возможности

- VLESS + Reality, Trojan, VMess, Shadowsocks, **SOCKS**, **Hysteria2**, WireGuard
- Caddy: HTTPS панели на `:8443`, Xray на `:443`
- Скрипты установки, UFW, бэкап
- Документация по эксплуатации и диагностике связности

## Быстрый старт

```bash
git clone https://github.com/afsunafsun/afsun-proxy.git /opt/afsun-proxy
cd /opt/afsun-proxy
cp .env.example .env
nano .env   # PROXY_DOMAIN и CADDY_EMAIL — ваш домен
sudo bash scripts/install.sh
sudo bash scripts/bootstrap.sh   # панель + VLESS + подписка — готово
```

`bootstrap.sh`: настройка 3X-UI, UFW, VLESS Reality :443, HTTPS-подписка. Подробно: [docs/DEPLOY.md](docs/DEPLOY.md).

Панель: `https://YOUR_DOMAIN:8443/<webBasePath>/` — путь выводит `setup-xui.sh`.

## Документация

- [Развёртывание](docs/DEPLOY.md)
- [Эксплуатация](docs/OPERATIONS.md) — порты, HY2, SOCKS, обновление Docker-образов
- [Настройка инбаундов и клиентов](docs/INBOUND-SETUP.md) — VLESS, Reality, SOCKS, все поля панели
- [Доступ к панели](docs/ACCESS.md)
- [Клиенты](docs/CLIENT.md)
- [Диагностика связности](docs/TROUBLESHOOTING.md)
- [Архитектура](docs/ARCHITECTURE.md)
- [Безопасность](docs/SECURITY.md)
- [Разработка и релизы](docs/CONTRIBUTING.md)

## Структура

```
/opt/afsun-proxy/       # код (git)
/var/lib/afsun-proxy/   # данные
├── x-ui/db/
├── x-ui/cert/
├── caddy/
└── hysteria/
```

## Лицензия

MIT — см. LICENSE. 3X-UI/Xray — свои лицензии.
