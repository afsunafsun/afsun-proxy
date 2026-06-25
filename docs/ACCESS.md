# Доступ к панели

## HTTPS (рекомендуется)

```
https://YOUR_DOMAIN:8443/<webBasePath>/
```

`webBasePath` задаётся в 3X-UI (например `/panel-xxxx/`).

## Безопасность

- 3X-UI слушает **127.0.0.1:2053** — снаружи только Caddy
- Сильный пароль + уникальный `webBasePath`
- Не открывать порт 2053 в UFW

## SSH-туннель (запасной)

```bash
ssh -L 2053:127.0.0.1:2053 root@YOUR_VPS_IP
# http://127.0.0.1:2053/<webBasePath>/
```
