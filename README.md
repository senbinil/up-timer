# UpTimer

[![CI](https://img.shields.io/github/actions/workflow/status/senbinil/up-timer/ci.yml)](https://github.com/senbinil/up-timer/actions) [![Docker Pulls](https://img.shields.io/docker/pulls/binilsn/up-timer)](https://hub.docker.com/r/binilsn/up-timer) [![Docker Image Size](https://img.shields.io/docker/image-size/binilsn/up-timer)](https://hub.docker.com/r/binilsn/up-timer) [![Docker Version](https://img.shields.io/docker/v/binilsn/up-timer?sort=semver)](https://hub.docker.com/r/binilsn/up-timer) [![License](https://img.shields.io/github/license/senbinil/up-timer)](https://github.com/senbinil/up-timer/blob/main/LICENSE) [![Ruby](https://img.shields.io/badge/Ruby-4.0.5-red)](https://www.ruby-lang.org)

Having a hard time tracking your services? UpTimer gives you real-time monitoring, instant alerts, and a beautiful dashboard — zero infrastructure overhead.

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
  -e SOLID_QUEUE_IN_PUMA=true \
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
  -e SOLID_QUEUE_IN_PUMA=true \
  binilsn/up-timer:latest
```

### With email (Mailgun)

```bash
docker run -d -p 3000:80 \
  -e ADMIN_EMAILS=admin@example.com \
  -e MAIL_PROVIDER=mailgun \
  -e MAILGUN_API_KEY=key-xxxxxx \
  -e MAILGUN_DOMAIN=mg.example.com \
  -e SOLID_QUEUE_IN_PUMA=true \
  binilsn/up-timer:latest
```

### Environment Variables

| Variable              | Required | Default               | Description                                                                            |
| --------------------- | -------- | --------------------- | -------------------------------------------------------------------------------------- |
| `ADMIN_EMAILS`        | ❌       | —                     | Comma-separated emails assigned admin role                                             |
| `MAIL_PROVIDER`       | ❌       | —                     | `resend` or `mailgun`. When empty, accounts auto-verify and alert emails are skipped   |
| `MAIL_FROM`           | ❌       | `noreply@example.com` | From address for outgoing emails                                                       |
| `RESEND_API_KEY`      | \*       | —                     | Required when `MAIL_PROVIDER=resend`                                                   |
| `MAILGUN_API_KEY`     | \*       | —                     | Required when `MAIL_PROVIDER=mailgun`                                                  |
| `MAILGUN_DOMAIN`      | \*       | —                     | Required when `MAIL_PROVIDER=mailgun`                                                  |
| `APP_HOST`            | ❌       | `example.com`         | Host used for links in email templates                                                 |
| `SOLID_QUEUE_IN_PUMA` | ❌       | –                     | Set to `true` to run job worker in Puma process (required for single-container deploy) |
| `DB_PROVIDER`         | ❌       | `sqlite`              | `sqlite` or `postgres`. Switches database adapter at runtime                           |
| `DATABASE_URL`        | \*       | —                     | PostgreSQL connection string: `postgres://user:pass@host:5432/dbname`                  |
| `POSTGRES_USER`       | \*       | —                     | PostgreSQL username                                                                    |
| `POSTGRES_PASSWORD`   | \*       | —                     | PostgreSQL password                                                                    |

\* Required when `DB_PROVIDER=postgres`.

\* Required when using that provider.

## Production

See **[deploy/](deploy/)** for the full deployment system — an interactive installer that auto-detects your infrastructure and generates the right configuration.

**One-liner deploy (no clone needed):**

```bash
bash <(curl -sSL https://raw.githubusercontent.com/senbinil/up-timer/main/deploy/installer.sh)
```

Or from a cloned repo:

```bash
./deploy/installer.sh
```

### Supported Modes

| Mode                   | Best for                                               | Open ports        | SSL                           |
| ---------------------- | ------------------------------------------------------ | ----------------- | ----------------------------- |
| **Standalone Traefik** | Fresh VPS, want automatic HTTPS                        | 80, 443           | Auto Let's Encrypt            |
| **Kamal Proxy**        | Kamal 2.x with kamal-proxy already running             | None              | Auto Let's Encrypt (optional) |
| **Existing Traefik**   | Kamal 1.x or standalone Traefik already running        | None              | Existing proxy handles it     |
| **Nginx**              | Nginx already on the host                              | None              | Existing proxy handles it     |
| **Cloudflare Tunnel**  | Zero open ports, Cloudflare handles TLS                | None              | Cloudflare                    |
| **IP-only**            | Minimal deployment, testing, or external load balancer | 80 (configurable) | None                          |
| **Coolify**            | Self-hosted PaaS — web UI deploy                       | None              | Auto Let's Encrypt            |

All modes use the **same immutable Docker image**. Only the surrounding infrastructure differs.

```bash
docker pull binilsn/up-timer:latest
```

[Docker Hub](https://hub.docker.com/r/binilsn/up-timer)

See [deploy/README.md](deploy/README.md) for full environment variable reference.

### Deploy Files

| File                                       | Purpose                                 |
| ------------------------------------------ | --------------------------------------- |
| [deploy/installer.sh](deploy/installer.sh) | Interactive CLI wizard                  |
| [deploy/.env.example](deploy/.env.example) | All environment variables documented    |
| [deploy/README.md](deploy/README.md)       | Full deployment guide & scenarios       |
| [Dockerfile](Dockerfile)                   | Application image build                 |
| [docker-compose.yml](docker-compose.yml)   | Quick start with Docker (local/testing) |
| [.kamal/](.kamal/)                         | Kamal deploy config (optional)          |

### Coexistence with Kamal

If Kamal is already running on the VPS, the installer auto-detects the `kamal-proxy` container. Select **Integrate with existing Kamal Proxy** to attach to Kamal's network and register the route with zero port conflicts.

```bash
./deploy/installer.sh
```

## Architecture

### Public Status Page

<img width="1892" height="860" alt="Public status page screenshot" src="https://github.com/user-attachments/assets/594a8a1d-618d-44e2-b99d-6535942a6709" />

### Application Overview

```mermaid
flowchart LR
    Browser["User Browser"] --> App["Rails Application"]
    App --> Jobs["SolidQueue Workers"]
    Jobs --> DB[("Database")]
    DB -->|"DB_PROVIDER=sqlite"| SQLite["SQLite3"]
    DB -->|"DB_PROVIDER=postgres"| PG["PostgreSQL"]
```

### Key Design Decisions

- **Adapter-based database** — switch between SQLite and PostgreSQL via `DB_PROVIDER` env var. Zero code changes. See [docs/adapter-pattern.md](docs/adapter-pattern.md).
- **SolidQueue** — database-backed job queue (no Redis dependency). Scheduler and workers run in-process.
- **Immutable Docker image** — same image deployed across all environments. Configuration via environment variables.
- **Thruster** — production web server wrapper with asset caching, compression, and X-Sendfile support.

### Thread count

`RAILS_MAX_THREADS` controls the entire thread pool:

| Component           | Threads                 | Config                                                             |
| ------------------- | ----------------------- | ------------------------------------------------------------------ |
| Puma web            | `RAILS_MAX_THREADS`     | `config/puma.rb`                                                   |
| Solid Queue workers | `RAILS_MAX_THREADS`     | `config/queue.yml`                                                 |
| DB connection pool  | `RAILS_MAX_THREADS x 2` | `config/database.yml` (overridden by `DATABASE_URL` when using PG) |

The doubled pool covers both Puma web threads and Solid Queue workers sharing the same database connections.

The installer auto-detects a value based on available RAM (shown as hint), but always defaults the prompt to `3`. You can change it manually:

```bash
# With docker run
docker run -d -p 3000:80 \
  -e ADMIN_EMAILS=admin@example.com \
  -e RAILS_MAX_THREADS=12 \
  -e SOLID_QUEUE_IN_PUMA=true \
  binilsn/up-timer:latest

# With docker compose
echo "RAILS_MAX_THREADS=12" >> .env
docker compose up -d
```

Default is `3`. Suggested range for 200 monitors with Solid Queue is 8–16.

## Authentication

Authentication is handled by Rodauth.

### Routes

| Route             | Description            |
| ----------------- | ---------------------- |
| `/login`          | Sign in                |
| `/create-account` | Register new user      |
| `/reset-password` | Request password reset |
| `/logout`         | Sign out               |

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

| Role             | Access                                                                           |
| ---------------- | -------------------------------------------------------------------------------- |
| **viewer**       | Dashboard, Nodes (view), Alerts (view), Public status page, Personal settings    |
| **collaborator** | Everything viewer can + Nodes (CRUD), Alerts (create/resolve), Personal settings |
| **admin**        | Everything above + Integrations, Email notifications toggle, User promotion      |

## Alert Triggers

Alert triggers define event types that can fire notifications. The system uses a **single alert per failure** model:

- **Node goes down** → 1 auto-alert created with the "Node Offline" trigger
- **Node recovers** → the auto-alert is resolved automatically
- **Manual alerts** → users pick a trigger type, which is saved to the alert

### Email control per trigger

Admins control which triggers send email notifications from the **Integrations** page:

| Trigger              | Auto-created           | Email notification |
| -------------------- | ---------------------- | ------------------ |
| Node Offline         | ✅ When node goes down | Togglable          |
| Critical Errors      | ❌ Manual only         | Togglable          |
| Degraded Performance | ❌ Manual only         | Togglable          |
| Security Breach      | ❌ Manual only         | Togglable          |
| Maintenance Window   | ❌ Manual only         | Togglable          |
| Custom               | ❌ Manual only         | Togglable          |

Email is only sent when the trigger's **Email** toggle is enabled on the Integrations page, regardless of the global email notifications setting.

## Background Jobs

SolidQueue powers all background processing with a recurring schedule defined in `config/recurring.yml`.

### Recurring Schedule

| Task                                        | Environment | Frequency               |
| ------------------------------------------- | ----------- | ----------------------- |
| `MonitorSchedulerJob`                       | dev + prod  | Every 30 seconds        |
| `DataRetentionJob`                          | dev + prod  | Every day at 3am        |
| `SolidQueue::Job.clear_finished_in_batches` | prod only   | Every hour at minute 12 |

### Jobs

| Job                   | Purpose                                                                                                                                                                                             |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MonitorSchedulerJob` | Iterates all monitors and enqueues a `MonitorCheckJob` for any whose last check is older than its configured `check_interval`                                                                       |
| `MonitorCheckJob`     | Performs an HTTP GET against a monitor's URL; records response time, status code, and up/down state; manages incident lifecycle (creates on first failure, resolves all open incidents on recovery) |
| `DataRetentionJob`    | Purges `MonitorCheck` records older than 30 days and resolved `Incident` records older than 90 days                                                                                                 |

Start the worker with `bin/jobs` (already included in `bin/dev`).

## Development

### Prerequisites

- Ruby 4.0.5 (see `.ruby-version`)
- SQLite3
- [RVM](https://rvm.io) (recommended for Ruby version management)

### Setup

```bash
# Clone and enter project
git clone https://github.com/senbinil/up-timer.git
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
bundle exec rspec
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

| Layer         | Technology                                             |
| ------------- | ------------------------------------------------------ |
| Framework     | Rails 8.1                                              |
| Ruby          | 4.0.5                                                  |
| Database      | SQLite3 (default) / PostgreSQL (via adapter)           |
| Auth          | Rodauth with RBAC (viewer / collaborator / admin)      |
| CSS           | Tailwind CSS v4                                        |
| JS            | Stimulus + Turbo                                       |
| Charts        | Chartkick + Chart.js                                   |
| Jobs          | SolidQueue                                             |
| Mailer        | letter_opener (dev), Action Mailer with AlertMailer    |
| Feature Flags | — (removed, toggle moved to per-trigger email control) |
| Icons         | Lucide                                                 |
| Tools         | Tippy.js (tooltips), Pagy (pagination)                 |
| Deployment    | Docker, Kamal, Docker Compose                          |
| CI            | GitHub Actions (scan, lint, test, deploy_test)         |

## Creating a Release

```bash
# Tag and push — CI builds and pushes to Docker Hub
git tag v1.0.0
git push origin v1.0.0
```

Or create a [GitHub Release](https://github.com/senbinil/up-timer/releases) via the UI — same result.
