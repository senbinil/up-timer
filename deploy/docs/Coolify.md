# Coolify Deployment Guide

Deploy UpTimer on [Coolify](https://coolify.io) — a self-hosted PaaS that handles reverse proxy, SSL, and Docker orchestration for you.

## Why Coolify

- No manual Traefik/Nginx setup — Coolify handles routing and Let's Encrypt
- One-click deploys from Docker Hub
- Built-in health checks and auto-restart
- Persistent storage management

## Setup

### 1. Create a New Service

In your Coolify dashboard:

1. Go to your project → **New Service**
2. Choose **Docker Image** as the source
3. Image: `binilsn/up-timer:latest` (or pin a version like `binilsn/up-timer:v1.0.0`)

### 2. Configure Networking

| Field | Value |
|---|---|
| Ports Exposes | `80` |
| Ports Mapped | *leave empty — Coolify proxies automatically* |

Coolify runs its own Traefik reverse proxy. It will route traffic to port 80 inside the container — no manual port mapping needed.

### 3. Add a Domain

1. In the service settings → **Domains**
2. Add your domain: `uptime.example.com`
3. Coolify auto-provisions a Let's Encrypt certificate

### 4. Environment Variables

Under **Environment Variables**, add:

| Variable | Required | Example |
|---|---|---|
| `RAILS_MASTER_KEY` | ❌ | From `config/master.key` (auto-generated if omitted) |
| `ADMIN_EMAILS` | ❌ | `admin@example.com` |
| `APP_HOST` | ❌ | `uptime.example.com` |
| `MAIL_PROVIDER` | ❌ | `resend` or `mailgun` |
| `MAIL_FROM` | ❌ | `noreply@example.com` |
| `RESEND_API_KEY` | * | `re_xxxxxx` |
| `MAILGUN_API_KEY` | * | `key-xxxxxx` |
| `MAILGUN_DOMAIN` | * | `mg.example.com` |

\* Required when using that email provider.

### 5. Persistent Storage

To persist the SQLite database and uploads across redeploys:

Under **Persistent Storage**, add two volumes:

| Source Path | Mount Path |
|---|---|
| `/data/storage` | `/rails/storage` |
| `/data/db` | `/rails/db` |

### 6. Health Check

Under **Health Check**:

| Field | Value |
|---|---|
| Command | `curl -f http://localhost/up` |
| Interval | `10s` |
| Timeout | `3s` |
| Retries | `3` |

### 7. Deploy

Click **Deploy**. Coolify pulls the image, starts the container, provisions SSL, and routes your domain.

## Configuration by Scenario

### Minimal (testing)

```
RAILS_MASTER_KEY=
ADMIN_EMAILS=you@example.com
```

No master key needed — key auto-generated per session.

### With Email (Resend)

```
RAILS_MASTER_KEY=abc123...
ADMIN_EMAILS=admin@example.com
APP_HOST=uptime.example.com
MAIL_PROVIDER=resend
MAIL_FROM=noreply@uptime.example.com
RESEND_API_KEY=re_xxxxxx
```

## Updating

1. Go to your service in Coolify
2. Click **Redeploy**
3. Coolify pulls the latest image and restarts

Or enable **Auto-Deploy** on new Docker Hub tags in Coolify's source settings.

## Troubleshooting

**Service not starting:**
- Check Coolify logs in the service view
- Verify the health check endpoint is correct: `http://localhost/up`

**Domain not routing:**
- Verify DNS points to your Coolify server's IP
- Check Coolify's proxy logs

**Database resets on redeploy:**
- You forgot to add persistent storage volumes
- Add them and redeploy

**Session/cookie issues after redeploy:**
- You're using auto-generated `SECRET_KEY_BASE` (no master key provided)
- Provide `RAILS_MASTER_KEY` for persistent sessions
