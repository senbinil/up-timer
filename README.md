# UpTimer

Uptime monitoring dashboard for tracking service health, response times, and incidents.

<img width="1886" height="865" alt="Dashboard screenshot" src="https://github.com/user-attachments/assets/67e747b1-fc2d-4cd7-8f96-e27b6a6c7ad3" />

## Features

- **Monitor any HTTP endpoint** — configurable check interval and timeout per monitor
- **Real-time dashboard** — see up/down status, response times, and uptime percentages at a glance
- **Public status page** — share a read-only view of your service health
- **Incident management** — automatic incident creation on failure, resolution on recovery
- **Role-based access control** — viewer / collaborator / admin roles
- **Alert emails** — notified when services go down (optional, via Resend or Mailgun)
- **Data retention** — automatic cleanup of old checks and resolved incidents
- **Background scheduling** — checks run every 30 seconds via SolidQueue
- **Dark/light design** — high-contrast light operational system

## Quick Start

```bash
docker run -d -p 3000:80 \
  -e ADMIN_EMAILS=admin@example.com \
  binilsn/up-timer:latest
```

Opens at [http://localhost:3000](http://localhost:3000).

Repository: [hub.docker.com/r/binilsn/up-timer](https://hub.docker.com/r/binilsn/up-timer)

## Docker

### With email (Resend)

```bash
docker run -d -p 3000:80 \
  -e ADMIN_EMAILS=admin@example.com \
  -e MAIL_PROVIDER=resend \
  -e RESEND_API_KEY=re_xxxxxx \
  binilsn/up-timer:latest
```

### With email (Mailgun)

```bash
docker run -d -p 3000:80 \
  -e ADMIN_EMAILS=admin@example.com \
  -e MAIL_PROVIDER=mailgun \
  -e MAILGUN_API_KEY=key-xxxxxx \
  -e MAILGUN_DOMAIN=mg.example.com \
  binilsn/up-timer:latest
```

### Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `ADMIN_EMAILS` | ❌ | — | Comma-separated emails assigned admin role |
| `MAIL_PROVIDER` | ❌ | — | `resend` or `mailgun`. When empty, accounts auto-verify and alert emails are skipped |
| `MAIL_FROM` | ❌ | `noreply@example.com` | From address for outgoing emails |
| `RESEND_API_KEY` | * | — | Required when `MAIL_PROVIDER=resend` |
| `MAILGUN_API_KEY` | * | — | Required when `MAIL_PROVIDER=mailgun` |
| `MAILGUN_DOMAIN` | * | — | Required when `MAIL_PROVIDER=mailgun` |
| `APP_HOST` | ❌ | `example.com` | Host used for links in email templates |

\* Required when using that provider.

## Production

See **[deploy/](deploy/)** for the full deployment system — an interactive installer that auto-detects your infrastructure and generates the right configuration.

**One-liner deploy (no clone needed):**

```bash
bash <(curl -sSL https://raw.githubusercontent.com/binilsn/up-timer/main/deploy/installer.sh)
```

Or from a cloned repo:

```bash
./deploy/installer.sh
```

### Supported Modes

| Mode | Best for | Open ports | SSL |
|---|---|---|---|
| **Standalone Traefik** | Fresh VPS, want automatic HTTPS | 80, 443 | Auto Let's Encrypt |
| **Kamal Proxy** | Kamal 2.x with kamal-proxy already running | None | Auto Let's Encrypt (optional) |
| **Existing Traefik** | Kamal 1.x or standalone Traefik already running | None | Existing proxy handles it |
| **Nginx** | Nginx already on the host | None | Existing proxy handles it |
| **Cloudflare Tunnel** | Zero open ports, Cloudflare handles TLS | None | Cloudflare |
| **IP-only** | Minimal deployment, testing, or external load balancer | 80 (configurable) | None |
| **Coolify** | Self-hosted PaaS — web UI deploy | None | Auto Let's Encrypt |

All modes use the **same immutable Docker image**. Only the surrounding infrastructure differs.

### Deploy Files

| File | Purpose |
|---|---|
| [deploy/installer.sh](deploy/installer.sh) | Interactive CLI wizard |
| [deploy/.env.example](deploy/.env.example) | All environment variables documented |
| [deploy/README.md](deploy/README.md) | Full deployment guide & scenarios |
| [Dockerfile](Dockerfile) | Application image build |
| [docker-compose.yml](docker-compose.yml) | Standalone production compose (Traefik + Let's Encrypt) |
| [.kamal/](.kamal/) | Kamal deploy config (optional) |

### Coexistence with Kamal

If Kamal is already running on the VPS, the installer auto-detects the `kamal-proxy` container. Select **Integrate with existing Kamal Proxy** to attach to Kamal's network and register the route with zero port conflicts.

```bash
./deploy/installer.sh
```

## Architecture

### Public Status Page

<img width="1892" height="860" alt="Public status page screenshot" src="https://github.com/user-attachments/assets/594a8a1d-618d-44e2-b99d-6535942a6709" />

### Application Structure

```
┌──────────────────────────────────────────────────┐
│                   User Browser                    │
└──────────────┬──────────────────┬────────────────┘
               │                  │
    ┌──────────▼──────────┐  ┌───▼────────────┐
    │   Dashboard (auth)   │  │  Public Status  │
    │   /dashboard         │  │  /status/:slug  │
    └──────────┬──────────┘  └────────────────┘
               │
    ┌──────────▼──────────────────────────────────┐
    │              Rails 8 Application             │
    │                                              │
    │  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
    │  │ Rodauth  │  │  Flipper  │  │  Pagy    │   │
    │  │  Auth    │  │Features  │  │Pagination│   │
    │  └──────────┘  └──────────┘  └──────────┘   │
    │                                              │
    │  ┌──────────────────────────────────┐        │
    │  │        SolidQueue Workers         │        │
    │  │  MonitorScheduler ──► every 30s  │        │
    │  │  MonitorCheck      ──► HTTP GET  │        │
    │  │  DataRetention     ──► daily 3am │        │
    │  └──────────────────────────────────┘        │
    │                                              │
    │  ┌──────────────────────────────────┐        │
    │  │         SQLite3 Database          │        │
    │  │  monitors / checks / incidents    │        │
    │  │  users / flipper_features         │        │
    │  └──────────────────────────────────┘        │
    └──────────────────────────────────────────────┘
```

### Key Design Decisions

- **SQLite3** — single-file database, zero operational overhead. Suitable for single-server deployments.
- **SolidQueue** — database-backed job queue (no Redis dependency). Scheduler and workers run in-process.
- **Immutable Docker image** — same image deployed across all environments. Configuration via environment variables.
- **Thruster** — production web server wrapper with asset caching, compression, and X-Sendfile support.

## Authentication

Authentication is handled by Rodauth.

### Routes

| Route | Description |
|---|---|
| `/login` | Sign in |
| `/create-account` | Register new user |
| `/reset-password` | Request password reset |
| `/logout` | Sign out |

After login, users are redirected to `/dashboard`.

### Email configuration

Email delivery is **optional**. When a mail provider is configured, the full auth flow works as expected — verification emails, password reset emails, and login change confirmations are sent. Without a provider, the app degrades gracefully:

- **Self-registration** works and accounts are auto-verified
- **Password reset** remains functional (token is generated but not emailed)
- **Login change** and **email verification** are disabled
- **Alert emails** are skipped silently

### Admin assignment

Set `ADMIN_EMAILS` environment variable with a comma-separated list:

```bash
ADMIN_EMAILS=admin@example.com docker compose up -d
```

Users registering with those emails get the **admin** role. Everyone else defaults to **viewer**.

## RBAC

| Role | Access |
|---|---|
| **viewer** | Dashboard, Nodes (view), Alerts (view), Public status page, Personal settings |
| **collaborator** | Everything viewer can + Nodes (CRUD), Alerts (create/resolve), Personal settings |
| **admin** | Everything above + Integrations, Email notifications toggle, User promotion |

## Background Jobs

SolidQueue powers all background processing with a recurring schedule defined in `config/recurring.yml`.

### Recurring Schedule

| Task | Environment | Frequency |
|---|---|---|
| `MonitorSchedulerJob` | dev + prod | Every 30 seconds |
| `DataRetentionJob` | dev + prod | Every day at 3am |
| `SolidQueue::Job.clear_finished_in_batches` | prod only | Every hour at minute 12 |

### Jobs

| Job | Purpose |
|---|---|
| `MonitorSchedulerJob` | Iterates all monitors and enqueues a `MonitorCheckJob` for any whose last check is older than its configured `check_interval` |
| `MonitorCheckJob` | Performs an HTTP GET against a monitor's URL; records response time, status code, and up/down state; manages incident lifecycle (creates on first failure, resolves all open incidents on recovery) |
| `DataRetentionJob` | Purges `MonitorCheck` records older than 30 days and resolved `Incident` records older than 90 days |

Start the worker with `bin/jobs` (already included in `bin/dev`).

## Development

### Prerequisites

- Ruby 4.0.5 (see `.ruby-version`)
- SQLite3
- [RVM](https://rvm.io) (recommended for Ruby version management)

### Setup

```bash
# Clone and enter project
git clone https://github.com/binilsn/up-timer.git
cd up-timer

# Configure admin emails (copy and edit)
cp .env.example .env
# Edit .env with your email to get admin access:
# ADMIN_EMAILS=you@example.com

# Activate Ruby (RVM users)
rvm use

# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate
rails db:seed

# Start development server
bin/dev
```

`bin/dev` starts:
- **Web server** (Puma) on `http://localhost:3000`
- **CSS watcher** (Tailwind CSS v4)
- **Job worker** (SolidQueue) for background jobs

### Mailer in Development

Emails open in browser via [letter_opener](https://github.com/ryanb/letter_opener). No SMTP configuration needed.

### Creating Monitored Endpoints

1. Login and navigate to `/nodes`
2. Click **Create Node**
3. Fill in name, URL, check interval (seconds), and timeout (seconds)
4. The scheduler picks it up within 30 seconds

### Design System

See [DESIGN.md](DESIGN.md) for the full design token specification (colors, typography, components).

## Testing

```bash
rails test
```

### Installer Tests

The deployment installer has its own test suite (bash-based):

```bash
# Unit tests — compose generation
bash spec/installer_test.sh

# Integration tests — .env to docker-compose config resolution
bash spec/installer_integration_test.sh
```

These run automatically in CI on every pull request.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Rails 8.1 |
| Ruby | 4.0.5 |
| Database | SQLite3 |
| Auth | Rodauth with RBAC (viewer / collaborator / admin) |
| CSS | Tailwind CSS v4 |
| JS | Stimulus + Turbo |
| Charts | Chartkick + Chart.js |
| Jobs | SolidQueue |
| Mailer | letter_opener (dev), Action Mailer with AlertMailer |
| Feature Flags | Flipper (email_notifications toggle) |
| Icons | Lucide |
| Tools | Tippy.js (tooltips), Pagy (pagination) |
| Deployment | Docker, Kamal, Docker Compose |
| CI | GitHub Actions (scan, lint, test, deploy_test) |

## Creating a Release

```bash
# Tag and push — CI builds and pushes to Docker Hub
git tag v1.0.0
git push origin v1.0.0
```

Or create a [GitHub Release](https://github.com/binilsn/up-timer/releases) via the UI — same result.
