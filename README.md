# UpTimer

Uptime monitoring dashboard for tracking service health, response times, and incidents.

<img width="1886" height="865" alt="image" src="https://github.com/user-attachments/assets/67e747b1-fc2d-4cd7-8f96-e27b6a6c7ad3" />

## Public Status Page
<img width="1892" height="860" alt="image" src="https://github.com/user-attachments/assets/594a8a1d-618d-44e2-b99d-6535942a6709" />




## Production Deployment

See **[deploy/](deploy/)** for the full deployment system — interactive installer that auto-detects your infrastructure and generates the right configuration.

**One-liner deploy (no clone needed):**

```bash
bash <(curl -sSL https://raw.githubusercontent.com/senbinil/up-timer/main/deploy/installer.sh)
```

Or from a cloned repo:

```bash
./deploy/installer.sh
```

Supports: **Standalone Traefik, Existing Traefik (Kamal), Nginx, Cloudflare Tunnel, IP-only, Coolify** — all from the same immutable Docker image.

See [deploy/README.md](deploy/README.md) for full environment variable reference.
### Deploy Files

| File | Purpose |
|---|---|
| [deploy/installer.sh](deploy/installer.sh) | Interactive CLI wizard |
| [deploy/.env.example](deploy/.env.example) | All environment variables documented |
| [deploy/README.md](deploy/README.md) | Deployment guide & scenarios |
| [Dockerfile](Dockerfile) | Application image build |
| [docker-compose.yml](docker-compose.yml) | Quick start with Docker (local/testing) |
| [.kamal/](.kamal/) | Kamal deploy config (optional) |

### Quick start (Docker)

```bash
# Without email (auto-verify, no alert emails)
docker run -d -p 3000:80 \
  -e ADMIN_EMAILS=admin@example.com \
  -e SOLID_QUEUE_IN_PUMA=true \
  binilsn/up-timer:latest

# With email (Resend)
docker run -d -p 3000:80 \
  -e ADMIN_EMAILS=admin@example.com \
  -e MAIL_PROVIDER=resend \
  -e RESEND_API_KEY=re_xxxxxx \
  -e SOLID_QUEUE_IN_PUMA=true \
  binilsn/up-timer:latest
```

Opens at `http://localhost:3000`.

### Thread count

`RAILS_MAX_THREADS` controls the entire thread pool:

| Component | Threads | Config |
|---|---|---|
| Puma web | `RAILS_MAX_THREADS` | `config/puma.rb` |
| Solid Queue workers | `RAILS_MAX_THREADS` | `config/queue.yml` |
| DB connection pool | `RAILS_MAX_THREADS x 2` | `config/database.yml` |

The doubled pool covers both Puma web threads and Solid Queue workers
sharing the same database connections.

The installer auto-detects a value based on available RAM (shown as hint),
but always defaults the prompt to `3`. You can change it manually:

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

Repository: [hub.docker.com/r/binilsn/up-timer](https://hub.docker.com/r/binilsn/up-timer)

## Auth

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

| Variable | Required | Default | Description |
|---|---|---|---|
| `MAIL_PROVIDER` | ❌ | — | `resend` or `mailgun` |
| `MAIL_FROM` | ❌ | `noreply@example.com` | From address for outgoing emails |
| `RESEND_API_KEY` | * | — | Required when `MAIL_PROVIDER=resend` |
| `MAILGUN_API_KEY` | * | — | Required when `MAIL_PROVIDER=mailgun` |
| `MAILGUN_DOMAIN` | * | — | Required when `MAIL_PROVIDER=mailgun` |
| `APP_HOST` | ❌ | `example.com` | Host used for links in email templates |

\* Required when using that provider.

### Admin assignment

Set `ADMIN_EMAILS` environment variable with a comma-separated list:

```bash
ADMIN_EMAILS=admin@example.com docker compose up -d
```

Users registering with those emails get the **admin** role. Everyone else defaults to **viewer**.

## Role-Based Access Control

| Role | Access |
|---|---|
| **viewer** | Dashboard, Nodes (view), Alerts (view), Public status page, Personal settings |
| **collaborator** | Everything viewer can + Nodes (CRUD), Alerts (create/resolve), Personal settings |
| **admin** | Everything above + Integrations, Email notifications toggle, User promotion |

## Alert Triggers

Alert triggers define event types that can fire notifications. The system uses a **single alert per failure** model:

- **Node goes down** → 1 auto-alert created with the "Node Offline" trigger
- **Node recovers** → the auto-alert is resolved automatically
- **Manual alerts** → users pick a trigger type, which is saved to the alert

### Email control per trigger

Admins control which triggers send email notifications from the **Integrations** page:

| Trigger | Auto-created | Email notification |
|---|---|---|
| Node Offline | ✅ When node goes down | Togglable |
| Critical Errors | ❌ Manual only | Togglable |
| Degraded Performance | ❌ Manual only | Togglable |
| Security Breach | ❌ Manual only | Togglable |
| Maintenance Window | ❌ Manual only | Togglable |
| Custom | ❌ Manual only | Togglable |

Email is only sent when the trigger's **Email** toggle is enabled on the Integrations page,
regardless of the global email notifications setting.

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

For production email setup, see [Auth → Email configuration](#email-configuration).

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
| Icons | Lucide |
| Tools | Tippy.js (tooltips), Pagy (pagination) |

## Creating a Release

```bash
# Tag and push — CI builds and pushes to Docker Hub
git tag v1.0.0
git push origin v1.0.0
```

Or create a [GitHub Release](https://github.com/binilsn/up-timer/releases) via the UI — same result.

## Setup (Development)

### Prerequisites

- Ruby 4.0.5 (see `.ruby-version`)
- SQLite3
- [RVM](https://rvm.io) (recommended for Ruby version management)

```bash
# Clone and enter project
git clone https://github.com/senbinil/up-timer.git
cd up-timer

# Configure admin emails (copy and edit)
cp deploy/.env.example .env
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

## Testing

```bash
bundle exec rspec
```
