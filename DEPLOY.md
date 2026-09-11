# Deploying Somani

The app deploys as a Docker container via [Kamal](https://kamal-deploy.org).
`config/deploy.yml` is still the generated template — fill in your real
values before the first deploy.

## 1. Prerequisites

- A Linux server (1 vCPU / 2GB is enough to start) reachable over SSH
- DNS: `somani.me` and `www.somani.me` → the server's IP
- Docker Hub (or ghcr.io) account for the image registry
- Locally: `gem install kamal` (or use `bin/kamal`), `docker` running

## 2. Fill in config/deploy.yml

```yaml
servers:
  web:
    - YOUR.SERVER.IP.HERE

registry:
  server: registry.hub.docker.com
  username: your-dockerhub-user
  password:
    - KAMAL_REGISTRY_PASSWORD

proxy:
  ssl: true
  host: somani.me

builder:
  arch: amd64   # set remote: ssh://... if building on an arm64 Mac feels slow
```

**Critical for Somani:** the database accessory must be Postgres **with
pgvector** — not the MySQL example in the template:

```yaml
accessories:
  db:
    image: pgvector/pgvector:pg16
    host: YOUR.SERVER.IP.HERE
    port: "127.0.0.1:5432"
    env:
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data
env:
  clear:
    DB_HOST: somani-db
```

## 3. Secrets

Create `.kamal/secrets` (gitignored) or use `kamal secrets push`:

```
KAMAL_REGISTRY_PASSWORD=...
RAILS_MASTER_KEY=...            # config/master.key — same one you use locally
POSTGRES_PASSWORD=...
GEMINI_API_KEY=...
GEMINI_MODEL=gemini-2.5-flash
AZURE_SPEECH_KEY=...
AZURE_SPEECH_REGION=...
CLOUDINARY_URL=...
SENTRY_DSN=...                  # optional — error tracking stays off without it
```

Every variable in `.template.env` that isn't in `env.clear` belongs here.

## 4. First deploy

```bash
bin/kamal setup          # boots the server: proxy, db accessory, app, assets
bin/kamal app exec "bin/rails db:prepare"   # create + migrate the database
bin/kamal deploy         # every deploy after that
```

Verify:

```bash
curl https://somani.me/up          # → 200
bin/kamal logs -f                  # watch the first requests land
```

## 5. Post-deploy checklist

- [ ] Sign up, upload the sample menu, run one full adventure
- [ ] `bin/kamal app exec "bin/rails llm:usage"` — confirm calls are being costed
- [ ] Reminders: Solid Queue runs inside Puma (`SOLID_QUEUE_IN_PUMA: true`),
      so the recurring schedule in `config/recurring.yml` starts on its own
- [ ] One-time: `bin/kamal app exec "bin/rails jlpt:verify_levels[conflicts]"`
      — settles the 243 disputed word levels (~2.7h, resumable, Ctrl-C safe)
- [ ] Backups: the `somani_storage` volume holds Active Storage files —
      snapshot it; Postgres data lives in the db accessory's `data` volume

## 6. Routine

| Cadence | Command |
|---|---|
| Every deploy | `bin/kamal deploy` |
| Weekly cost check | `bin/kamal app exec "bin/rails llm:usage"` |
| After a bad deploy | `bin/kamal rollback` |

Migrations run automatically on deploy when listed in `bin/docker-entrypoint`;
verify new migrations appear in `db/migrate` before deploying.
