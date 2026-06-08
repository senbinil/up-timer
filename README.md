# UpTimer

Uptime monitoring dashboard for tracking service health, response times, and incidents.

## Prerequisites

- Ruby 4.0.5 (see `.ruby-version`)
- SQLite3
- [RVM](https://rvm.io) (recommended for Ruby version management)

## Setup

```bash
# Clone and enter project
git clone https://github.com/binilsn/up-timer.git
cd up-timer

# Activate Ruby (RVM users)
rvm use

# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate

# Start development server
bin/dev
```

`bin/dev` starts:
- **Web server** (Puma) on `http://localhost:3000`
- **CSS watcher** (Tailwind CSS v4)
- **Job worker** (SolidQueue) for background jobs

## Auth

Authentication is handled by Rodauth. Default routes:

| Route | Description |
|---|---|
| `/login` | Sign in |
| `/create-account` | Register new user |
| `/logout` | Sign out |

After login, users are redirected to `/dashboard`.

## Background Jobs

SolidQueue runs the following:

| Job | Schedule | Description |
|---|---|---|
| `MonitorSchedulerJob` | Every 30 seconds | Finds due monitors and enqueues health checks |
| `MonitorCheckJob` | On-demand | Performs HTTP GET to monitor URL, records result |

Start the worker with `bin/jobs` (already included in `bin/dev`).

## Creating Monitored Endpoints

1. Login and navigate to `/nodes`
2. Click **Create Node**
3. Fill in name, URL, check interval (seconds), and timeout (seconds)
4. The scheduler picks it up within 30 seconds

## Mailer (Development)

Emails open in browser via [letter_opener](https://github.com/ryanb/letter_opener). No SMTP configuration needed.

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
| Auth | Rodauth |
| CSS | Tailwind CSS v4 |
| JS | Stimulus + Turbo |
| Charts | Chartkick + Chart.js |
| Jobs | SolidQueue |
| Mailer | letter_opener (dev) |
| Icons | Lucide |

## Testing

```bash
rails test
```
