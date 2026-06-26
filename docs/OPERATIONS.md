# Эксплуатация

Повседневные задачи после установки.

## Порядок первой настройки

```bash
sudo bash scripts/install.sh
sudo bash scripts/bootstrap.sh   # всё остальное: панель, UFW, VLESS, подписка
```

Или по шагам: `setup-xui.sh` → `setup-ufw.sh` → `setup-vless-inbound.sh` → `finish-panel-setup.sh`.

Опционально после bootstrap:
   - `sudo bash scripts/setup-hysteria2-server.sh` — HY2 для Streisand/Shadowrocket
   - `VLESS_ALT_PORT=2087 sudo bash scripts/setup-vless-alt-port.sh` — запасной TCP-порт
   - `sudo bash scripts/tune-reality-settings.sh` — dest/SNI/fingerprint

## UFW — порты

**Панель порты в UFW не открывает.** Базовые — `setup-ufw.sh`. Inbound'ы — `sync-ufw-inbounds.sh`.

| Порт | Протокол | Сервис | Как открыть |
|------|----------|--------|-------------|
| 22 | tcp | SSH | `setup-ufw.sh` |
| 80 | tcp | ACME | `setup-ufw.sh` |
| 443 | tcp | VLESS | `setup-ufw.sh` + inbound |
| 8443 | tcp | Панель (Caddy) | `setup-ufw.sh` |
| 10808 | tcp/udp | SOCKS | inbound в панели → `sync-ufw-inbounds.sh` |
| 8444 | udp | Hysteria2 (official) | `setup-hysteria2-server.sh` → sync |
| 2087 | tcp | VLESS alt | `setup-vless-alt-port.sh` → sync |

После **любого нового inbound в панели вручную**:

```bash
sudo bash scripts/sync-ufw-inbounds.sh
```

Подробно: [SECURITY.md](SECURITY.md).

## Inbounds в панели — что держать

| Inbound | Действие |
|---------|----------|
| VLESS Reality **443** | Основной, оставить |
| VLESS Reality **2087** (или другой alt) | Запасной, по желанию |
| **SOCKS 10808** | Для интеграций, оставить |
| Hysteria2 **8444** в панели (Xray) | **Удалить** — используется official HY2 |
| VLESS **8445** и прочие тестовые | **Удалить**, если DPI режет |

## Hysteria2 (official)

- Сервис: `systemctl status afsun-hysteria2`
- Конфиг: `/var/lib/afsun-proxy/hysteria/server.yaml`
- Подписка: строка HY2 из **external link** (скрипт добавляет в БД)
- **Новый клиент:** обновите `password` в `server.yaml` или перезапустите `setup-hysteria2-server.sh`

Xray inbound «Hysteria2» в панели **не использовать** — несовместим с обычными HY2-клиентами.

## SOCKS

- Listen: `0.0.0.0:10808` (пустой `listen` в панели)
- Логин/пароль — в settings inbound, **не** из подписки VLESS
- Для доступа **с другой машины** нужен `ufw allow 10808/tcp`
- Поле `"ip": "127.0.0.1"` в settings — адрес UDP relay SOCKS, **не** ограничение bind

## Новый клиент VLESS

1. Панель → клиент → subId
2. При необходимости HY2 → `setup-hysteria2-server.sh`
3. Клиент: удалить старый профиль → импорт подписки

## Бэкап

```bash
bash scripts/backup-xui.sh
```

## Обновление 3X-UI и Caddy

Панель работает в **Docker**. Версия задаётся тегом образа в `.env` (`XUI_VERSION`, `CADDY_VERSION`), а не кнопкой **«Обновить панель»** на дашборде 3X-UI.

Кнопка в UI рассчитана на установку через **systemd** (`update.sh` + `x-ui.service`). В контейнере сервиса нет — обновление завершается с ошибкой `x-ui service unit not installed`, версия не меняется. Это ожидаемое поведение, не баг afsun-proxy.

**3X-UI:**

1. Посмотреть актуальный релиз: [3X-UI releases](https://github.com/MHSanaei/3x-ui/releases)
2. В `.env`: `XUI_VERSION=3.4.1` (без префикса `v`)
3. Обновить:

```bash
sudo bash scripts/update-xui.sh
```

Или вручную:

```bash
cd /opt/afsun-proxy
nano .env   # XUI_VERSION=…
docker compose pull x-ui
docker compose up -d x-ui
```

Клиенты, inbound'ы и настройки хранятся в `${DATA_DIR}/x-ui/db` (volume) — при смене образа **не теряются**.

**Caddy** — аналогично: `CADDY_VERSION` в `.env`, затем `docker compose pull caddy && docker compose up -d caddy`.

После обновления репозитория afsun-proxy (`git pull`) перечитайте `.env.example` — там могут быть новые переменные.

## Проблемы связности

→ [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
