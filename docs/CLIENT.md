# Клиенты

## VLESS + Reality (VPN)

| Клиент | Платформа |
|--------|-----------|
| v2rayNG | Android |
| v2RayTun | iOS |
| Hiddify | Android / iOS / Desktop |
| Streisand | iOS |
| Nekoray | Desktop |

Импорт: **Subscription URL** из 3X-UI (QR или ссылка).

Обязательно:
- `flow = xtls-rprx-vision`
- режим VPN / TUN
- DNS: удалённый (1.1.1.1 или 8.8.8.8)

## Hysteria2

| Клиент | Платформа |
|--------|-----------|
| Streisand | iOS |
| Shadowrocket | iOS |
| Hiddify | Android / iOS / Desktop |

Строка HY2 приходит в подписке (external link). Сервер — **official** Hysteria2, не Xray inbound.

## SOCKS5

| Поле | Значение |
|------|----------|
| Host | YOUR_DOMAIN |
| Port | 10808 (если настроен) |
| Login / Password | из карточки клиента в 3X-UI |

Подходит: Telegram Desktop, curl, антидетект-браузеры. **Не входит** в подписку VLESS — настройка вручную.

## Проверка

- IP: https://ifconfig.me или аналог → IP вашего VPS
- В панели растёт **traffic** у клиента

Проблемы связности → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
