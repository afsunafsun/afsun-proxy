# Troubleshooting — проблемы связности

Технические симптомы и шаги диагностики. Администратор сам оценивает законность использования в своей среде.

## Симптомы

- Пинг / TCP до сервера **есть**
- Клиент: **timeout**, трафик в панели **0**
- Несколько приложений — одно и то же

→ Часто режется **протокол или TLS-handshake**, а не IP целиком.

## Что пробовать (по порядку)

### 1. Свежая подписка

Удалить старый профиль → импорт новой ссылки из 3X-UI.

### 2. Fragment (настройка клиента)

Если TCP доходит, но трафик 0 (обрыв на TLS ClientHello):

**v2RayTun (iOS):** Настройки профиля → Fragment → включить  
Параметры: `100-200,10-20,1-3`

**v2rayNG (Android):** настройки → fragment `100-200,10-20,1-3`

### 3. Другая сеть

Мобильный интернет ↔ Wi‑Fi (разные маршруты у провайдера).

### 4. Альтернативный inbound

Дополнительный VLESS Reality на другом TCP-порту:

```bash
VLESS_ALT_PORT=2087 sudo bash scripts/setup-vless-alt-port.sh
```

Обновить подписку в приложении.

### 5. Hysteria2 (UDP)

Для клиентов Streisand / Shadowrocket / Hiddify:

```bash
sudo bash scripts/setup-hysteria2-server.sh
```

**Не** используйте inbound Hysteria2 в панели Xray — он несовместим с этими клиентами.

### 6. Параметры Reality

```bash
sudo bash scripts/tune-reality-settings.sh
```

Или вручную: другой **dest/SNI** (живой HTTPS на 443), fingerprint `firefox` / `safari`.

### 7. Relay

Промежуточный VPS — если ничего не помогает.

## Диагностика

| Проверка | OK | Плохо |
|----------|-----|-------|
| E2E с сервера (`curl` через локальный xray) | IP сервера | чинить Xray |
| traffic в панели | растёт | клиент не аутентифицировался |
| timeout с клиента | см. fragment / alt port | — |

## SOCKS vs VPN

SOCKS (`:10808`) — **отдельный** протокол, не подписка VLESS. Настройка вручную: [INBOUND-SETUP.md](INBOUND-SETUP.md).
