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

## Коммиты

- **Не коммитьте с prod-сервера** под `root@hostname` — только с вашего ПК
- Email: GitHub noreply `ID+username@users.noreply.github.com` или ваш публичный email
- **Cursor:** Settings → отключить добавление `Co-authored-by: Cursor` в коммиты (иначе `cursoragent` попадёт в Contributors)

```bash
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
