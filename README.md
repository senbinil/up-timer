# UpTimer

[![CI](https://img.shields.io/github/actions/workflow/status/senbinil/up-timer/ci.yml)](https://github.com/senbinil/up-timer/actions) [![Docker Pulls](https://img.shields.io/docker/pulls/binilsn/up-timer)](https://hub.docker.com/r/binilsn/up-timer) [![Docker Image Size](https://img.shields.io/docker/image-size/binilsn/up-timer)](https://hub.docker.com/r/binilsn/up-timer) [![Docker Version](https://img.shields.io/docker/v/binilsn/up-timer?sort=semver)](https://hub.docker.com/r/binilsn/up-timer) [![License](https://img.shields.io/github/license/senbinil/up-timer)](https://github.com/senbinil/up-timer/blob/main/LICENSE) [![Ruby](https://img.shields.io/badge/Ruby-4.0.9-red)](https://www.ruby-lang.org)

Having a hard time tracking your services? UpTimer gives you real-time monitoring, instant alerts, and a beautiful dashboard — zero infrastructure overhead.

<img width="1920" height="946" alt="Screenshot 2026-10-10 190248" src="https://github.com/user-attachments/assets/dcdf8934-7a5e-48cf-a0ca-2bf23ab66cf9" />

## Features

- **Monitor any HTTP endpoint** — configurable check interval, timeout, and HTTP method per monitor
- **Flexible checks** — GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS; custom request bodies and expected status codes
- **Down threshold** — only alert after a configurable number of consecutive failures
- **SSL monitoring** — tracks certificate validity and expiry for HTTPS endpoints
- **Real-time dashboard** — up/down status, response times, and uptime percentages at a glance
- **Public status page** — share a read-only view of your service health
- **Incident management** — automatic incident creation on failure, resolution on recovery
- **Alert emails** — per-trigger email toggles delivered to configured recipients (optional, via Resend or Mailgun)
- **Role-based access control** — viewer / collaborator / admin roles
- **Registration control** — admins can enable/disable public self-registration from Site Settings, with an audit log of every change
- **Data retention** — automatic cleanup of old checks and resolved incidents
- **Background scheduling** — checks run every 30 seconds via SolidQueue
- **Organization** — tags, pause/resume, and custom ordering for your monitors
- **Geo-location** — resolves each service's geographic location
- **Dark/light design** — high-contrast light operational system

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
  - [Docker](#docker)
  - [Production deployment](#production-deployment)
  - [Local development](#local-development)
- [Usage](#usage)
  - [Creating monitored endpoints](#creating-monitored-endpoints)
  - [Public status page](#public-status-page)
  - [Authentication](#authentication)
  - [Registration](#registration)
  - [RBAC](#rbac)
  - [Alert triggers](#alert-triggers)
- [Configuration](#configuration)
  - [Environment variables](#environment-variables)
  - [Thread count](#thread-count)
- [Architecture](#architecture)
- [Background jobs](#background-jobs)
- [Testing](#testing)
- [Tech stack](#tech-stack)
- [Creating a release](#creating-a-release)
- [Troubleshooting](#troubleshooting)

## Quick Start

```bash
docker run -d -p 3000:80 \
  -e ADMIN_EMAILS=admin@example.com \
  -e SOLID_QUEUE_IN_PUMA=true \
  binilsn/up-timer:latest
```

Opens at [http://localhost:3000](http://localhost:3000). Register with `admin@example.com` to get the admin role.

## Installation

### Docker

```bash
docker pull binilsn/up-timer:latest
```

[Docker Hub](https://hub.docker.com/r/binilsn/up-timer) · [docker-compose.yml](docker-compose.yml) for local/test runs.

#### With email (Resend)

```bash
docker run -d -p 3000:80 \
  -e ADMIN_EMAILS=admin@example.com \
  -e MAIL_PROVIDER=resend \
  -e RESEND_API_KEY=re_xxxxxx \
  -e SOLID_QUEUE_IN_PUMA=true \
  binilsn/up-timer:latest
```

#### With email (Mailgun)

```bash
docker run -d -p 3000:80 \
  -e ADMIN_EMAILS=admin@example.com \
  -e MAIL_PROVIDER=mailgun \
  -e MAILGUN_API_KEY=key-xxxxxx \
  -e MAILGUN_API_HOST=api.mailgun.net \
  -e MAILGUN_DOMAIN=mg.example.com \
  -e SOLID_QUEUE_IN_PUMA=true \
  binilsn/up-timer:latest
```

See [Environment variables](#environment-variables) for the full reference.

### Production deployment

See **[deploy/](deploy/)** for the full deployment system — an interactive installer that auto-detects your infrastructure and generates the right configuration.

**One-liner deploy (no clone needed):**

```bash
bash <(curl -sSL https://raw.githubusercontent.com/senbinil/up-timer/main/deploy/installer.sh)
```

Or from a cloned repo:

```bash
./deploy/installer.sh
```

#### Supported modes

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

#### Deploy files

| File                                       | Purpose                                 |
| ------------------------------------------ | --------------------------------------- |
| [deploy/installer.sh](deploy/installer.sh) | Interactive CLI wizard                  |
| [deploy/.env.example](deploy/.env.example) | All environment variables documented    |
| [deploy/README.md](deploy/README.md)       | Full deployment guide & scenarios       |
| [Dockerfile](Dockerfile)                   | Application image build                 |
| [docker-compose.yml](docker-compose.yml)   | Quick start with Docker (local/testing) |
| [.kamal/](.kamal/)                         | Kamal deploy config (optional)          |

#### Coexistence with Kamal

If Kamal is already running on the VPS, the installer auto-detects the `kamal-proxy` container. Select **Integrate with existing Kamal Proxy** to attach to Kamal's network and register the route with zero port conflicts.

```bash
./deploy/installer.sh
```

### Local development

#### Prerequisites

- Ruby 4.0.9 (see `.ruby-version`)
- SQLite3
- [RVM](https://rvm.io) (recommended for Ruby version management)

#### Setup

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
bin/rails db:create db:migrate db:seed

# Start development server
bin/dev
```

`bin/dev` starts:

- **Web server** (Puma) on `http://localhost:3000`
- **CSS watcher** (Tailwind CSS v4)
- **Job worker** (SolidQueue) for background jobs

Emails open in browser via [letter_opener](https://github.com/ryanb/letter_opener). No SMTP configuration needed.

## Usage

### Creating monitored endpoints

1. Login and navigate to `/nodes`
2. Click **Create Node**
3. Fill in name, URL, HTTP method, check interval, and timeout
4. The scheduler picks it up within 30 seconds

### Public status page

<img width="1920" height="946" alt="Screenshot 2026-10-10 185810" src="https://github.com/user-attachments/assets/91f022e2-1e3b-4646-8e03-1fa45c89698e" />

The public status page lives at the root URL (`/`) and shows a read-only view of your service health. Toggle a monitor's public listing from its detail page.

### Authentication

Authentication is handled by Rodauth.

| Route                    | Description                              |
| ------------------------ | ---------------------------------------- |
| `/login`                 | Sign in                                  |
| `/create-account`        | Register new user (when registration is enabled) |
| `/reset-password-request` | Request password reset                  |
| `/reset-password`        | Set a new password                       |
| `/logout`                | Sign out                                 |

After login, users are redirected to `/dashboard`.

#### Email configuration

Email delivery is **optional**. When a mail provider is configured, the full auth flow works as expected — verification emails, password reset emails, and login change confirmations are sent. Without a provider, the app degrades gracefully:

- **Self-registration** works (when registration is enabled) and accounts are auto-verified
- **Password reset** remains functional (token is generated but not emailed)
- **Login change** and **email verification** are disabled
- **Alert emails** are skipped silently

#### Admin assignment

Set `ADMIN_EMAILS` environment variable with a comma-separated list:

```bash
ADMIN_EMAILS=admin@example.com docker compose up -d
```

Users registering with those emails get the **admin** role. Everyone else defaults to **viewer**.

### Registration

Self-registration can be turned on or off by an admin from **Site Settings** (`/admin/settings`). The setting is stored in the database (default: **enabled**) and applies immediately across all app instances — no restart required.

When registration is **disabled**:

- The **Create Account** link is hidden on the login page
- `/create-account` shows a "Registration is currently disabled" message instead of the form
- The registration endpoint is rejected **server-side** via Rodauth's `before_create_account` hook, so the gate cannot be bypassed by posting directly

The signup form collects **Email**, **Name**, **Password**, and a required **terms of service / privacy policy** acceptance checkbox. Name and compliance are validated on both the client and the server.

Every toggle is recorded in the **action log** (visible on the Site Settings page), noting who made the change and the resulting state.

### RBAC

| Role             | Access                                                                                   |
| ---------------- | ---------------------------------------------------------------------------------------- |
| **viewer**       | Dashboard, Nodes (view), Alerts (view), Public status page, Personal settings            |
| **collaborator** | Everything viewer can + Nodes (CRUD), Alerts (create/resolve), Personal settings         |
| **admin**        | Everything above + Integrations (trigger email toggles & recipients), User promotion, Site Settings (registration toggle) |

### Alert triggers

Alert triggers define event types that can fire notifications. The system uses a **single alert per failure** model:

- **Node goes down** → 1 auto-alert created with the "Node Offline" trigger
- **Node recovers** → the auto-alert is resolved automatically
- **Manual alerts** → users pick a trigger type, which is saved to the alert

#### Email control per trigger

Admins control which triggers send email notifications from the **Integrations** page:

| Trigger              | Auto-created           | Email notification |
| -------------------- | ---------------------- | ------------------ |
| Node Offline         | ✅ When node goes down | Togglable          |
| Critical Errors      | ❌ Manual only         | Togglable          |
| Degraded Performance | ❌ Manual only         | Togglable          |
| Security Breach      | ❌ Manual only         | Togglable          |
| Maintenance Window   | ❌ Manual only         | Togglable          |
| Custom               | ❌ Manual only         | Togglable          |

Email is sent for a trigger only when its **Email** toggle is enabled on the Integrations page.

## Configuration

### Environment variables

| Variable              | Default               | Description                                                                            |
| --------------------- | --------------------- | -------------------------------------------------------------------------------------- |
| `ADMIN_EMAILS`        | —                     | Comma-separated emails granted the admin role on registration                          |
| `MAIL_PROVIDER`       | —                     | `resend` or `mailgun`. When empty, accounts auto-verify and alert emails are skipped   |
| `MAIL_FROM`           | `noreply@example.com` | From address for outgoing emails                                                       |
| `RESEND_API_KEY`      | —                     | Required when `MAIL_PROVIDER=resend`                                                   |
| `MAILGUN_API_KEY`     | —                     | Required when `MAIL_PROVIDER=mailgun`                                                  |
| `MAILGUN_API_HOST`    | `api.mailgun.net`     | Mailgun API hostname (e.g. `api.eu.mailgun.net` for EU region)                         |
| `MAILGUN_DOMAIN`      | —                     | Required when `MAIL_PROVIDER=mailgun`                                                  |
| `APP_HOST`            | `example.com`         | Host used for links in email templates                                                 |
| `SOLID_QUEUE_IN_PUMA` | —                     | Set to `true` to run the job worker inside Puma (required for single-container deploys) |
| `ZJIT_ENABLE`         | `false`               | Set to `true` to run with the experimental ZJIT compiler (no-op if unsupported)        |
| `RAILS_MAX_THREADS`   | `3`                   | Puma threads and SolidQueue worker threads (DB pool is 2× this value)                  |
| `JOB_CONCURRENCY`     | `1`                   | Number of SolidQueue worker processes                                                  |
| `DB_PROVIDER`         | `sqlite`              | `sqlite` or `postgres`. Switches database adapter at runtime                           |
| `DATABASE_URL`        | —                     | PostgreSQL connection string (`postgres://user:pass@host:5432/dbname`); required when `DB_PROVIDER=postgres` |

> **Note:** the deployment installer additionally generates `POSTGRES_USER` / `POSTGRES_PASSWORD` for its Postgres compose override. The application itself only reads `DATABASE_URL` — see [deploy/README.md](deploy/README.md).

### Thread count

`RAILS_MAX_THREADS` controls the entire thread pool:

| Component           | Threads                 | Config                                                             |
| ------------------- | ----------------------- | ------------------------------------------------------------------ |
| Puma web            | `RAILS_MAX_THREADS`     | `config/puma.rb`                                                   |
| Solid Queue workers | `RAILS_MAX_THREADS`     | `config/queue.yml` (× `JOB_CONCURRENCY` processes)                 |
| DB connection pool  | `RAILS_MAX_THREADS x 2` | `config/database.yml` (overridden by `DATABASE_URL` when using PG) |

The doubled pool covers both Puma web threads and Solid Queue workers sharing the same database connections. A dedicated `dashboard_broadcast` worker (1 thread / 1 process) is always reserved for real-time broadcasts.

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

### ZJIT compiler (optional)

Ruby 4.0's experimental ZJIT compiler is opt-in — the default is **off**. Requires the
0.5.1+ image.

```bash
# deploy/.env
ZJIT_ENABLE=true
```

Then re-create the container (`./deploy/installer.sh` → **Update**). Nothing is rebuilt:
ZJIT is compiled into the official `ruby:4.0` image, so only the launch flag changes. Set
`ZJIT_ENABLE=false` (or remove it) to turn it back off.

> **Upgrading an existing install?** Installer **Update** does not regenerate the compose
> file, so `ZJIT_ENABLE` may not be forwarded yet. See
> [docs/troubleshooting.md#jit-zjit--yjit](docs/troubleshooting.md#jit-zjit--yjit).

While ZJIT is on, YJIT is disabled — Ruby runs only one JIT at a time.

Verify from the boot log — `+ZJIT` appears only when it is enabled:

```bash
docker compose … logs | grep 'Ruby version'
# * Ruby version: ruby 4.0.9 … +ZJIT +PRISM [x86_64-linux]
```

A `docker exec … ruby -e 'RubyVM::ZJIT.enabled?'` shell bypasses the entrypoint and always
reports `false`. If the interpreter lacks ZJIT, boot logs `... has no ZJIT support;
continuing without JIT` and the app runs normally.

## Architecture

### Application overview

```mermaid
flowchart LR
    Browser["User Browser"] --> App["Rails Application"]
    App --> Jobs["SolidQueue Workers"]
    Jobs --> DB[("Database")]
    DB -->|"DB_PROVIDER=sqlite"| SQLite["SQLite3"]
    DB -->|"DB_PROVIDER=postgres"| PG["PostgreSQL"]
```

### Key design decisions

- **Adapter-based database** — switch between SQLite and PostgreSQL via `DB_PROVIDER` env var. Zero code changes. See [docs/adapter-pattern.md](docs/adapter-pattern.md).
- **SolidQueue** — database-backed job queue (no Redis dependency). Scheduler and workers run in-process.
- **Live broadcasting** — dashboard and status page update in real time via Turbo Streams. See [docs/broadcasting-architecture.md](docs/broadcasting-architecture.md).
- **Immutable Docker image** — same image deployed across all environments. Configuration via environment variables.
- **Thruster** — production web server wrapper with asset caching, compression, and X-Sendfile support.

### Debugging

See [docs/troubleshooting.md](docs/troubleshooting.md) for common commands, deploy gotchas,
and JIT checks.

## Background jobs

SolidQueue powers all background processing with a recurring schedule defined in `config/recurring.yml`.

### Recurring schedule

| Task                                        | Environment | Frequency               |
| ------------------------------------------- | ----------- | ----------------------- |
| `MonitorSchedulerJob`                       | dev + prod  | Every 30 seconds        |
| `DashboardBroadcastJob`                     | dev + prod  | Every 2 seconds         |
| `DataRetentionJob`                          | dev + prod  | Every day at 3am        |
| `SolidQueue::Job.clear_finished_in_batches` | prod only   | Every hour at minute 12 |

### Jobs

| Job                    | Purpose                                                                                                                                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MonitorSchedulerJob`  | Iterates active monitors and enqueues a `MonitorCheckJob` for any whose last check is older than its configured `check_interval`                                                                                             |
| `MonitorCheckJob`      | Runs the monitor's HTTP request (GET, HEAD, POST, PUT, PATCH, DELETE, or OPTIONS); records response time, status code, up/down state, and SSL certificate info; updates the incident lifecycle (creates on failure, resolves on recovery, honoring the down-threshold) |
| `DashboardBroadcastJob`| Pushes dashboard and public status page updates to browsers via Turbo Streams                                                                                                                                                |
| `GeoLocationJob`       | Resolves a monitor's geographic location from its URL                                                                                                                                                                       |
| `DataRetentionJob`     | Purges `MonitorCheck` records older than 30 days and resolved `Incident` records older than 90 days                                                                                                                         |

Start the worker with `bin/jobs` (already included in `bin/dev`).

## Testing

```bash
bundle exec rspec
```

### Installer tests

The deployment installer has its own test suite (bash-based):

```bash
# Unit tests — compose generation
bash spec/installer_test.sh

# Integration tests — .env to docker-compose config resolution
bash spec/installer_integration_test.sh
```

These run automatically in CI on every pull request.

## Tech stack

| Layer      | Technology                                        |
| ---------- | ------------------------------------------------- |
| Framework  | Rails 8.1                                         |
| Ruby       | 4.0.9                                             |
| Database   | SQLite3 (default) / PostgreSQL (via adapter)      |
| Auth       | Rodauth with RBAC (viewer / collaborator / admin) |
| CSS        | Tailwind CSS v4                                   |
| JS         | Stimulus + Turbo                                  |
| Charts     | Chartkick + Chart.js                              |
| Jobs       | SolidQueue                                        |
| Mailer     | Action Mailer + AlertMailer (Resend / Mailgun)    |
| Icons      | Lucide                                            |
| Tools      | Tippy.js (tooltips), Pagy (pagination)            |
| Deployment | Docker, Kamal, Docker Compose                     |
| CI         | GitHub Actions (scan, lint, test, deploy_test, PR review) |

## Creating a release

```bash
# Tag and push — CI builds and pushes to Docker Hub
git tag 1.0.0
git push origin 1.0.0
```

Or create a [GitHub Release](https://github.com/senbinil/up-timer/releases) via the UI — same result.

## Troubleshooting

### Deploying a release doesn't apply migrations (volume shadowing)

**Affected:** installers before **0.4.1** · **Fixed in:** **0.4.1**

If an upgrade ships a new migration but `db:migrate` / `db:prepare` never apply it (e.g. the
dashboard raises `undefined local variable or method 'location'`), a volume is shadowing the
app's `db/` directory — Docker seeds a volume only once, at first mount, so it hides every later
migration file from the container.

The full diagnosis and fix steps live in the deployment guide:
[`deploy/README.md` → Troubleshooting](deploy/README.md#troubleshooting).
