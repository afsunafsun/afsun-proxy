# Развёртывание

## Требования

- VPS с Ubuntu/Debian, root-доступ
- Домен с **A-записью** на IP сервера (для TLS панели и ACME)
- Открытые порты: 22, 80, 443, 8443 + inbound'ы через `sync-ufw-inbounds.sh` — см. [SECURITY.md](SECURITY.md)

## 1. Установка

```bash
git clone https://github.com/afsunafsun/afsun-proxy.git /opt/afsun-proxy
cd /opt/afsun-proxy
cp .env.example .env
nano .env   # PROXY_DOMAIN=your.domain.example, CADDY_EMAIL=you@example.com
sudo bash scripts/install.sh
sudo bash scripts/bootstrap.sh
```

`install.sh` — Docker, geofiles, Caddy.  
`bootstrap.sh` — панель, UFW, VLESS Reality :443, клиент, HTTPS-подписка.

## 2. Первый вход в 3X-UI

Логин/пароль/`webBasePath` — в выводе `bootstrap.sh` (или `setup-xui.sh` при ручной установке).

## 3. Inbound VLESS + Reality

**Автоматически** создаётся в `bootstrap.sh` (`scripts/setup-vless-inbound.sh`).

Ручная настройка и все поля панели: **[INBOUND-SETUP.md](INBOUND-SETUP.md)**.

Параметры по умолчанию:

| Поле | Значение |
|------|----------|
| Port | 443 |
| Security | Reality |
| Dest / Цель (target) | www.yahoo.com:443 / www.yahoo.com |
| Fingerprint | firefox |
| Flow | xtls-rprx-vision |

Переопределение: `REALITY_TARGET` (или `REALITY_DEST`), `REALITY_SNI`, `REALITY_FP`, `CLIENT_EMAIL`.

Смена dest/SNI после установки:

```bash
sudo bash scripts/tune-reality-settings.sh
```

## 4. E2E тест с сервера

Импортировать ссылку в xray на сервере или проверить рост трафика у клиента после подключения с телефона.

## 5. SOCKS (опционально)

Inbounds → SOCKS или Mixed → порт 10808 → клиент с логином/паролем.

```bash
ufw allow 10808/tcp
ufw allow 10808/udp
```

См. [INBOUND-SETUP.md](INBOUND-SETUP.md) и [OPERATIONS.md](OPERATIONS.md).

## 6. Hysteria2 (official, не Xray inbound)

Для клиентов Streisand / Shadowrocket / Hiddify:

```bash
sudo bash scripts/setup-hysteria2-server.sh
ufw allow 8444/udp
```

**Не** создавайте inbound Hysteria2 в панели Xray — он несовместим с обычными HY2-клиентами. Подписка добавляется скриптом через external link.

## 7. Альтернативный VLESS-порт (опционально)

```bash
VLESS_ALT_PORT=2087 sudo bash scripts/setup-vless-alt-port.sh
ufw allow 2087/tcp
```

## 8. Geofiles и подписка

```bash
sudo bash scripts/finish-panel-setup.sh
```

- Скачивает runetfreedom `geosite_ru-rules.dat` / `geoip_ru-blocked.dat` в `${DATA_DIR}/x-ui/geofiles/` и монтирует в Xray.
- В 3X-UI **3.4.0** geofiles можно добавить в панели: **Статус системы → Xray → Пользовательские GeoSite / GeoIP**, либо использовать уже смонтированные `ext:geosite_ru-rules.dat:ru-blocked`.
- Включает HTTPS-подписку через Caddy (`/sub/`, `/json/` на `:8443`).

После скрипта на телефоне: **удалить старый профиль** и импортировать ссылку подписки из вывода скрипта.

## Дальше

- Повседневные задачи → [OPERATIONS.md](OPERATIONS.md)
- Проблемы связности → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
