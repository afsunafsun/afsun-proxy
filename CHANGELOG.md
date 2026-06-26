# Changelog

Формат: [Keep a Changelog](https://keepachangelog.com/). Версии — [SemVer](https://semver.org/).

> **Как выйти релиз afsun-proxy**
>
> 1. Перенести `[Unreleased]` → `## [X.Y.Z] — дата` (версия **выбираете вы**, следующая по SemVer после последнего тега).
> 2. PR `develop` → `main`, merge.
> 3. На `main`: `git tag vX.Y.Z` и `git push origin main --tags`.
> 4. Workflow [`.github/workflows/release.yml`](.github/workflows/release.yml) по push тега `v*` **сам** создаёт GitHub Release.
> 5. Описание Release = содержимое секции `## [X.Y.Z]` в этом файле (тег `v2.2.0` ↔ заголовок `## [2.2.0]` — **должны совпадать**).
>
> Release в UI GitHub вручную создавать **не нужно**. Если секции в CHANGELOG нет — в Release попадёт только заголовок с номером тега.

## [Unreleased]

## [2.2.0] — 2026-06-26

### Added

- `scripts/ensure-xray-metrics.sh` — блоки `metrics` и `observatory` в шаблоне Xray (графики и health-check в панели), idempotent
- `scripts/update-xui.sh` — обновление 3X-UI через Docker-образ
- `.env.example` — опционально `XRAY_METRICS_*`, `XRAY_OBSERVATORY_*`
- `.cursor/rules/versions-and-docs.mdc` — правило для версий и документации

### Changed

- `finish-panel-setup.sh` / `bootstrap.sh` — metrics и Observatory настраиваются автоматически при первой установке
- `docs/OPERATIONS.md`, `docs/DEPLOY.md`, `docs/CONTRIBUTING.md` — обновление 3X-UI/Caddy в Docker (не кнопка в панели)
- **3X-UI 3.4.1** — версия по умолчанию в `.env.example`, `docker-compose.yml`

## [2.1.0] — 2026-06-25

### Added

- `scripts/bootstrap.sh` — установка «в одну команду»: панель, UFW, VLESS Reality, подписка
- `scripts/setup-vless-inbound.sh` — VLESS Reality :443 через API 3X-UI
- `scripts/fix-reality-target.sh` — поле **Цель** (`target`) для панели 3.4.0
- `scripts/sync-ufw-inbounds.sh` — UFW по включённым inbound'ам
- `scripts/setup-hysteria2-server.sh` — official Hysteria2 (systemd)
- `scripts/setup-vless-alt-port.sh`, `tune-reality-settings.sh`
- `scripts/configure-xui-subscription.sh`, `finish-panel-setup.sh`, `setup-geofiles.sh`
- `scripts/lib/` — API-токен, Reality keys
- docs: DISCLAIMER, ACCEPTABLE-USE, OPERATIONS, TROUBLESHOOTING, INBOUND-SETUP
- docs/CONTRIBUTING.md — ветки `develop` / `main`

### Changed

- Документация: нейтральная формулировка, placeholders вместо prod-доменов
- `install.sh` — Caddyfile из шаблона, geofiles до compose up
- `setup-xui.sh` — идемпотентный, пользователь по умолчанию `admin`
- `.env.example` — `proxy.example.com`; `Caddyfile` не в git
- CI: `docker compose config` с шаблоном Caddyfile

### Removed

- `docs/ANTI-DPI-RU.md` → `docs/TROUBLESHOOTING.md`
- `scripts/setup-hysteria-inbound.sh`, `scripts/tune-reality-anti-dpi.sh`
- `config/caddy/Caddyfile` из репозитория (локальный, из `.example`)

## [2.0.0] — 2026-06-24 _(внутренний, тег снят)_

Первый прототип 3X-UI + Caddy. Публичный релиз — **v2.1.0**.

[2.2.0]: https://github.com/afsunafsun/afsun-proxy/releases/tag/v2.2.0
[2.1.0]: https://github.com/afsunafsun/afsun-proxy/releases/tag/v2.1.0
