# UpTimer

Uptime monitoring dashboard for tracking service health, response times, and incidents.

<img width="1886" height="865" alt="image" src="https://github.com/user-attachments/assets/67e747b1-fc2d-4cd7-8f96-e27b6a6c7ad3" />

## Public Status Page
<img width="1892" height="860" alt="image" src="https://github.com/user-attachments/assets/594a8a1d-618d-44e2-b99d-6535942a6709" />

## Prerequisites

- Ruby 4.0.5 (see `.ruby-version`)
- SQLite3
- [RVM](https://rvm.io) (recommended for Ruby version management)

## Setup (Development)

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

## Production Deployment

See **[deploy/](deploy/)** for the full deployment system — interactive installer that auto-detects your infrastructure and generates the right configuration.

**One-liner deploy (no clone needed):**

```bash
curl -sSL https://raw.githubusercontent.com/binilsn/up-timer/main/deploy/installer.sh | bash
```

Or from a cloned repo:

```bash
./deploy/installer.sh
```

Supports: **Standalone Traefik, Existing Traefik (Kamal), Nginx, Cloudflare Tunnel, IP-only, Coolify** — all from the same immutable Docker image.

See [deploy/README.md](deploy/README.md) for full environment variable reference.

### One-command deploy (local testing)

```bash
docker run -d -p 3000:80 \
  -e ADMIN_EMAILS=admin@example.com \
  -e MAIL_PROVIDER=resend \
  -e RESEND_API_KEY=re_xxxxxx \
  binilsn/up-timer:latest
```

Opens at `http://localhost:3000`.

See [Mailer](#mailer) for email configuration.

Repository: [hub.docker.com/r/binilsn/up-timer](https://hub.docker.com/r/binilsn/up-timer)

## Auth

Authentication is handled by Rodauth.

### Routes

| Route | Description |
|---|---|
| `/login` | Sign in |
| `/create-account` | Register new user |
| `/logout` | Sign out |

After login, users are redirected to `/dashboard`.

### Admin assignment

Set `ADMIN_EMAILS` environment variable with a comma-separated list:

```bash
ADMIN_EMAILS=admin@example.com docker compose -f docker-compose.generated.yml --env-file deploy/.env up -d
```

Users registering with those emails get the **admin** role. Everyone else defaults to **viewer**.

## Role-Based Access Control

| Role | Access |
|---|---|
| **viewer** | Dashboard, Nodes (view), Alerts (view), Public status page |
| **collaborator** | Everything viewer can + Nodes (CRUD), Alerts (create/resolve) |
| **admin** | Everything above + Integrations, Settings, user promotion |

### Setting admins

Set `ADMIN_EMAILS` env var with a comma-separated list of emails:

```bash
ADMIN_EMAILS=alice@example.com,bob@example.com rails server
```

Users registering with these emails are auto-assigned the **admin** role. Everyone else defaults to **viewer**.

## Background Jobs & Scheduler

SolidQueue powers all background processing with a recurring schedule defined in `config/recurring.yml`.

### Recurring Schedule

| Task | Environment | Frequency |
|---|---|---|
| `MonitorSchedulerJob` | dev + prod | Every 30 seconds |
| `DataRetentionJob` | dev + prod | Every day at 3am |
| `SolidQueue::Job.clear_finished_in_batches` | prod only | Every hour at minute 12 |

### Jobs

| Job | File | Purpose |
|---|---|---|
| `MonitorSchedulerJob` | `app/jobs/monitor_scheduler_job.rb` | Iterates all monitors and enqueues a `MonitorCheckJob` for any whose last check is older than its configured `check_interval` |
| `MonitorCheckJob` | `app/jobs/monitor_check_job.rb` | Performs an HTTP GET against a monitor's URL; records response time, status code, and `up`/`down` state; manages `Incident` lifecycle (creates on first failure, resolves all open incidents on recovery) |
| `DataRetentionJob` | `app/jobs/data_retention_job.rb` | Purges `MonitorCheck` records older than 30 days and resolved `Incident` records older than 90 days |

Start the worker with `bin/jobs` (already included in `bin/dev`).

## Creating Monitored Endpoints

1. Login and navigate to `/nodes`
2. Click **Create Node**
3. Fill in name, URL, check interval (seconds), and timeout (seconds)
4. The scheduler picks it up within 30 seconds

## Mailer

### Development

Emails open in browser via [letter_opener](https://github.com/ryanb/letter_opener). No SMTP configuration needed.

### Production

Email supports **Resend** and **Mailgun**. Set `MAIL_PROVIDER` and the provider's credentials via environment variables. If no provider is configured, email delivery is silently disabled — no errors will be raised.

| Variable | Required | Default | Description |
|---|---|---|---|
| `MAIL_PROVIDER` | ❌ | — | `resend` or `mailgun` |
| `MAIL_FROM` | ❌ | `noreply@example.com` | From address for all outgoing emails |
| `RESEND_API_KEY` | * | — | Required when `MAIL_PROVIDER=resend` |
| `MAILGUN_API_KEY` | * | — | Required when `MAIL_PROVIDER=mailgun` |
| `MAILGUN_DOMAIN` | * | — | Required when `MAIL_PROVIDER=mailgun` |
| `APP_HOST` | ❌ | `example.com` | Host used for links in email templates |

*Required when using that provider.*

## Design System

See `DESIGN.md` for the full design token specification (colors, typography, components).

Built with:
- **Tailwind CSS v4** — utility-first CSS
- **Lucide** — icon library (CDN)
- **Chartkick** + Chart.js — bar/column charts
- **Stimulus** — JavaScript sprinkles (sidebar toggle, dropdown menu, password toggle)

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

## Creating a Release

```bash
# Tag and push — CI builds and pushes to Docker Hub
git tag v1.0.0
git push origin v1.0.0
```

Or create a [GitHub Release](https://github.com/binilsn/up-timer/releases) via the UI — same result.

## Testing

```bash
rails test
```
