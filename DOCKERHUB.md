# UpTimer

Self-hosted uptime monitoring with real-time dashboards, instant alerts, and public status pages. Ships as a single container: SQLite by default, SolidQueue running in-process, no Redis or external workers to operate.

## Why UpTimer

- **Any HTTP endpoint** — configurable interval, timeout, method, request body, and expected status code per monitor
- **Flexible checks** — GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS
- **Down threshold** — only alerts after a configurable number of consecutive failures
- **SSL monitoring** — certificate validity and expiry tracking
- **Real-time dashboard** — live up/down status and response times pushed over Turbo Streams
- **Public status page** — read-only shareable view of service health
- **Incidents** — created automatically on failure, resolved automatically on recovery
- **Alert email** — optional Resend or Mailgun delivery, with per-trigger toggles
- **Role-based access** — viewer / collaborator / admin
- **Data retention** — automatic cleanup of old checks and resolved incidents
- **PostgreSQL optional** — set `DB_PROVIDER=postgres` to switch adapters

## Quick start

```bash
docker run -d --name up-timer -p 3000:80 \
  -v up-timer-storage:/rails/storage \
  -e ADMIN_EMAILS=admin@example.com \
  -e SOLID_QUEUE_IN_PUMA=true \
  senbinil/up-timer:latest
```

Open `http://localhost:3000` and register with `admin@example.com` to get the admin role.

Or with Compose (includes the healthcheck and restart policy):

```bash
curl -O https://raw.githubusercontent.com/senbinil/up-timer/main/docker-compose.yml
docker compose up -d
```

The container listens on port `80` and expects persistent data in `/rails/storage` — always mount a volume there, or your monitors, incidents, and users disappear on the next deploy.

## Production install (guided)

For a real deployment, the shell installer wires up the container, TLS, and persistence for you — no repo clone required:

```bash
bash <(curl -sSL https://raw.githubusercontent.com/senbinil/up-timer/main/deploy/installer.sh)
```

Prefer to inspect it first:

```bash
curl -sSLO https://raw.githubusercontent.com/senbinil/up-timer/main/deploy/installer.sh
chmod +x installer.sh && ./installer.sh
```

It checks for Docker and the Compose plugin, then asks about domain, SSL, database, and email before writing `deploy/.env` and `docker-compose.generated.yml`. Running it again detects an existing install and offers an update path.

Supported modes:

| Mode                   | Approach                     | TLS                 |
| ---------------------- | ---------------------------- | ------------------- |
| **Standalone Traefik** | Bundled Traefik container    | Auto Let's Encrypt  |
| **Kamal Proxy**        | Existing kamal-proxy         | Let's Encrypt (opt) |
| **Existing Traefik**   | Your own Traefik             | Handled by yours    |
| **Nginx**              | Your own Nginx               | Handled by yours    |
| **Cloudflare Tunnel**  | cloudflared, no open ports   | Cloudflare          |
| **IP-only**            | Direct port binding          | None                |

Coolify is deployed from its own web dashboard rather than the installer.

Full guide, upgrade notes, and troubleshooting: [deploy/README.md](https://github.com/senbinil/up-timer/blob/main/deploy/README.md).

## Environment variables

| Variable               | Required | Default             | Description                                                       |
| ---------------------- | -------- | ------------------- | ----------------------------------------------------------------- |
| `ADMIN_EMAILS`         | ❌       | —                   | Comma-separated emails that get the admin role on registration    |
| `SECRET_KEY_BASE`      | ❌       | auto-generated      | Set explicitly to keep sessions across restarts                   |
| `APP_HOST`             | ❌       | `example.com`       | Host used to build links in alert and verification emails         |
| `SOLID_QUEUE_IN_PUMA`  | ❌       | —                   | Set to `true` to run background checks inside the web process      |
| `RAILS_MAX_THREADS`    | ❌       | `3`                 | Puma threads (and DB connection pool per worker)                  |
| `ZJIT_ENABLE`          | ❌       | `false`             | Enable Ruby's ZJIT for the app process                            |
| `DB_PROVIDER`          | ❌       | `sqlite`            | `sqlite` or `postgres`                                            |
| `DATABASE_URL`         | ❌       | —                   | PostgreSQL URL, required when `DB_PROVIDER=postgres`              |
| `MAIL_PROVIDER`        | ❌       | —                   | `resend` or `mailgun`; omit to disable email entirely             |
| `MAIL_FROM`            | ❌       | `noreply@example.com` | Sender address for alert and verification emails                |
| `RESEND_API_KEY`       | ❌       | —                   | Required when `MAIL_PROVIDER=resend`                              |
| `MAILGUN_API_KEY`      | ❌       | —                   | Required when `MAIL_PROVIDER=mailgun`                             |
| `MAILGUN_API_HOST`     | ❌       | —                   | Required when `MAIL_PROVIDER=mailgun`                             |
| `MAILGUN_DOMAIN`       | ❌       | —                   | Required when `MAIL_PROVIDER=mailgun`                             |

Without a mail provider, accounts are auto-verified and alert emails are skipped — monitoring, the dashboard, and status pages all keep working.

## Image tags

- `latest` — most recent stable release
- `X.Y.Z` — pinned release, e.g. `senbinil/up-timer:0.6.1` (tags carry no `v` prefix)

Images are multi-stage builds of this repository and publish only when a GitHub release is published.

## Links

- Source, issues, and changelog: [github.com/senbinil/up-timer](https://github.com/senbinil/up-timer)
- Deployment guides (Traefik, Nginx, Cloudflare Tunnel, Kamal, Coolify, IP-only): [deploy/README.md](https://github.com/senbinil/up-timer/blob/main/deploy/README.md)
- Full environment reference: [deploy/.env.example](https://github.com/senbinil/up-timer/blob/main/deploy/.env.example)
- Release notes: [CHANGELOG.md](https://github.com/senbinil/up-timer/blob/main/CHANGELOG.md)
