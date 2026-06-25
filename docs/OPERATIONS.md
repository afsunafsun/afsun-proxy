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

## Проблемы связности

→ [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
