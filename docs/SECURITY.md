# Безопасность

## Секреты и доступ

- `.env` — chmod 600, не в git
- Не коммитьте пароли, UUID, реальные подписки
- 3X-UI: listen **127.0.0.1**, сложный пароль, случайный `webBasePath`
- Порт **2053** — не открывать в UFW (панель только через Caddy :8443)
- Не держать IDE (Cursor) на прод-сервере
- Регулярно: `bash scripts/backup-xui.sh`

## Файрвол (UFW)

**3X-UI порты в UFW сама не открывает.** При «Создать входящее подключение» панель лишь подставляет свободный порт в конфиг Xray — `ufw` не трогает.

| Этап | Скрипт | Что открывает |
|------|--------|----------------|
| Базовая установка | `setup-ufw.sh` | 22, 80, 443, 8443 |
| Inbound'ы из панели/скриптов | `sync-ufw-inbounds.sh` | порты **включённых** inbound'ов (tcp/udp по протоколу) |
| Official Hysteria2 | `sync-ufw-inbounds.sh` | UDP-порт, если активен `afsun-hysteria2` |

После **любого нового inbound в панели**:

```bash
sudo bash scripts/sync-ufw-inbounds.sh
```

`bootstrap.sh` и наши setup-скрипты вызывают sync автоматически. При ручном создании в панели — **обязательно** sync вручную, иначе снаружи будет timeout.

Проверка: `sudo ufw status`

## Принцип минимальных портов

- Открывайте только то, что реально используете
- Отключённый inbound → правило UFW можно удалить: `ufw delete allow PORT/proto`
- Опциональные порты: 10808 (SOCKS), 8444/udp (HY2), 2087 (VLESS alt) — см. [OPERATIONS.md](OPERATIONS.md)

См. также [DISCLAIMER.md](DISCLAIMER.md) и [ACCEPTABLE-USE.md](ACCEPTABLE-USE.md).
