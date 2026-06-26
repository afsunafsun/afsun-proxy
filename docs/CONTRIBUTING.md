# Разработка и релизы

## Ветки

| Ветка | Назначение |
|-------|------------|
| **`develop`** | Ежедневная разработка, тесты, merge PR |
| **`main`** | Только стабильные релизы с тегами |

Не коммитьте напрямую в `main` без review — сначала `develop`.

## Workflow

```text
feature/*  →  develop  →  main  +  tag vX.Y.Z
```

1. Ветка от `develop`: `git checkout develop && git pull && git checkout -b feature/имя`
2. Коммит, push, PR в **`develop`**
3. CI (`validate.yml`) должен пройти
4. Когда готово к релизу: merge `develop` → `main`
5. На `main`:
   - обновить `CHANGELOG.md` (секция `[X.Y.Z]` + пустой `[Unreleased]`)
   - `git tag vX.Y.Z`
   - `git push origin main --tags`
6. GitHub → **Releases** → создать release по тегу
7. `develop` merge/rebase от `main`, чтобы ветки не разъехались

## Версии

- **SemVer:** `MAJOR.MINOR.PATCH`
- Тег = версия в CHANGELOG, например `v2.1.0`
- Версии компонентов — в `.env.example` (`XUI_VERSION`, `CADDY_VERSION`)

### Обновление 3X-UI / Caddy

При смене `XUI_VERSION` или `CADDY_VERSION`:

1. `.env.example` — актуальный тег образа
2. `docker-compose.yml` — fallback в `${XUI_VERSION:-…}` / `${CADDY_VERSION:-…}`
3. `scripts/update-xui.sh` — default в `${XUI_VERSION:-…}`
4. `CHANGELOG.md` — секция `[Unreleased]` → `Changed`
5. `docs/OPERATIONS.md`, `docs/DEPLOY.md` — примеры и формулировки «текущая версия»
6. `grep -r '3\.4\.' docs/ scripts/` — убрать устаревшие pin'ы (исторические `docs/releases/*` и закрытые секции CHANGELOG не трогать)
7. На prod: `.env` + `sudo bash scripts/update-xui.sh` (или `docker compose pull` + `up -d`)

Правило для Cursor: `.cursor/rules/versions-and-docs.mdc`

## Коммиты

- Коммиты — с вашего ПК, не с prod-сервера (`root@hostname`)
- Email: GitHub noreply или ваш публичный email

```bash
cp .env.example .env
cp config/caddy/Caddyfile.example config/caddy/Caddyfile
docker compose config
shellcheck scripts/*.sh scripts/lib/*.sh
```

## Установка для пользователей

С GitHub клонируют **`main`** (или тег релиза):

```bash
git clone https://github.com/afsunafsun/afsun-proxy.git /opt/afsun-proxy
git checkout v2.1.0   # опционально, зафиксировать версию
```
