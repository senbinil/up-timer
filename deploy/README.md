# UpTimer Deployment

Production deployment for any infrastructure — no application changes needed.

## Quick Start

**One-liner (no clone needed):**

```bash
bash <(curl -sSL https://raw.githubusercontent.com/binilsn/up-timer/main/deploy/installer.sh)
```

**From a cloned repo:**

```bash
./deploy/installer.sh
```

Answer a few questions and it auto-detects your environment, generates config, and starts the containers.

## Deployment Scenarios

| # | Mode | Best for | Open ports | SSL |
|---|---|---|---|---|
| 1 | **Standalone Traefik** | Fresh VPS, want automatic HTTPS | 80, 443 | Auto Let's Encrypt |
| 2 | **Existing Traefik** | Kamal or another Traefik already running | None | Existing proxy handles it |
| 3 | **Existing Nginx** | Nginx already on the host | None | Existing proxy handles it |
| 4 | **Cloudflare Tunnel** | Zero open ports, Cloudflare handles TLS | None | Cloudflare |
| 5 | **IP-only** | Testing, or external load balancer | 80 (configurable) | None |
| 6 | **Coolify** | Self-hosted PaaS — web UI deploy | None | Auto Let's Encrypt |

Coolify is deployed through its own web dashboard, not the installer. See [docs/Coolify.md](docs/Coolify.md).

## Directory Structure

```
deploy/
├── installer.sh              # Interactive CLI wizard
├── .env.example              # All environment variables documented
├── README.md                 # This file
│
├── compose/                  # App service definitions
│   ├── app.yml               # Base app (proxy-agnostic)
│   └── app-ip.yml            # IP-only variant (exposes port)
│
├── proxy/                    # Reverse proxy definitions
│   ├── traefik-standalone.yml  # New Traefik + Let's Encrypt
│   ├── traefik-existing.yml    # Labels for existing Traefik
│   └── nginx.yml               # Nginx service
│
├── tunnel/                   # Cloudflare Tunnel
│   └── cloudflared.yml       # cloudflared container
│
├── networking/               # Network definitions
│   ├── standalone.yml        # Bridge network
│   └── existing.yml          # External network (Kamal, etc.)
│
├── templates/                # Config templates
│   └── nginx.conf            # Nginx vhost (auto-generated)
│
└── docs/                     # Per-scenario guides
    ├── VPS.md
    ├── Traefik.md
    ├── Nginx.md
    └── Cloudflare.md
```

The application image (`binilsn/up-timer`) never changes across scenarios.
Only the surrounding infrastructure differs.

## Environment Variables

### App

| Variable | Required | Default | Description |
|---|---|---|---|
| `TAG` | ❌ | `latest` | Docker image tag (pin to a version for stability) |
| `RAILS_MASTER_KEY` | ❌ | auto-generated | Decrypts config/credentials (auto-generated if empty) |
| `ADMIN_EMAILS` | ❌ | — | Comma-separated emails auto-assigned admin role |
| `APP_HOST` | ❌ | `DOMAIN` | Host used in email links |
| `MAIL_PROVIDER` | ❌ | — | `resend` or `mailgun` (empty = disabled) |
| `MAIL_FROM` | ❌ | `noreply@example.com` | From address for outgoing emails |
| `RESEND_API_KEY` | * | — | Required if `MAIL_PROVIDER=resend` |
| `MAILGUN_API_KEY` | * | — | Required if `MAIL_PROVIDER=mailgun` |
| `MAILGUN_DOMAIN` | * | — | Required if `MAIL_PROVIDER=mailgun` |

\* Required when using that provider.

### Standalone Traefik

| Variable | Required | Default | Description |
|---|---|---|---|
| `DOMAIN` | ✅ | — | Public domain for your instance |
| `LETSENCRYPT_EMAIL` | ✅ | — | Email for cert expiry notices |
| `CF_DNS_API_TOKEN` | ✅ | — | Cloudflare API token (DNS:Edit) |
| `DNS_PROVIDER` | ❌ | `cloudflare` | DNS provider for ACME challenge |
| `ENTRYPOINT` | ❌ | `websecure` | Traefik entrypoint (web = HTTP only) |

### Existing Traefik

| Variable | Required | Default | Description |
|---|---|---|---|
| `DOMAIN` | ✅ | — | Public domain for routing rule |
| `TRAEFIK_NETWORK` | ✅ | — | External Docker network (auto-detected) |
| `ENTRYPOINT` | ❌ | `websecure` | Traefik entrypoint |

### Cloudflare Tunnel

| Variable | Required | Default | Description |
|---|---|---|---|
| `CF_TUNNEL_TOKEN` | ✅ | — | Tunnel token from Cloudflare Zero Trust |

### IP-only

| Variable | Required | Default | Description |
|---|---|---|---|
| `APP_PORT` | ❌ | `80` | Host port to bind |

## Updating

```bash
./deploy/installer.sh
# Select "Update" from the existing-deployment menu
```

Or manually:

```bash
docker compose pull
docker compose up -d --remove-orphans
```

### Tag Strategy

- `TAG=latest` — always pulls the newest image. Simple, but may pull breaking changes.
- `TAG=v1.0.0` — pins a specific version. Recommended for production stability.

## Coexistence with Kamal

If Kamal is already running on the VPS:

1. Run `./deploy/installer.sh`
2. It auto-detects the `kamal-proxy` container
3. Select **Existing Traefik** integration
4. The installer sets `TRAEFIK_NETWORK=kamal`

Your UpTimer instance attaches to Kamal's network with zero port conflicts.

## Manual Setup (without installer)

### Standalone Traefik

```bash
cp deploy/.env.example deploy/.env
# Fill in DOMAIN, LETSENCRYPT_EMAIL, CF_DNS_API_TOKEN (RAILS_MASTER_KEY optional)

docker compose \
  -f deploy/compose/app.yml \
  -f deploy/proxy/traefik-standalone.yml \
  -f deploy/networking/standalone.yml \
  --env-file deploy/.env \
  up -d
```

### Existing Traefik

```bash
cp deploy/.env.example deploy/.env
# Fill in DOMAIN, TRAEFIK_NETWORK

docker compose \
  -f deploy/compose/app.yml \
  -f deploy/proxy/traefik-existing.yml \
  -f deploy/networking/existing.yml \
  --env-file deploy/.env \
  up -d
```

### Cloudflare Tunnel

```bash
cp deploy/.env.example deploy/.env
# Fill in CF_TUNNEL_TOKEN

docker compose \
  -f deploy/compose/app.yml \
  -f deploy/tunnel/cloudflared.yml \
  -f deploy/networking/standalone.yml \
  --env-file deploy/.env \
  up -d
```

### IP-only

```bash
cp deploy/.env.example deploy/.env
# Fill in APP_PORT if not using default 80

docker compose \
  -f deploy/compose/app-ip.yml \
  -f deploy/networking/standalone.yml \
  --env-file deploy/.env \
  up -d
```

## Troubleshooting

### "port is already allocated"

Another service is using port 80 or 443. Use **Existing Traefik** or **Cloudflare Tunnel** mode instead.

### "network not found"

The external network doesn't exist. Verify with `docker network ls`. The installer auto-detects this.

### Traefik certificate not issued

- Verify DNS is pointed to the server
- Check `CF_DNS_API_TOKEN` has DNS:Edit permission
- Check logs: `docker compose logs traefik`

### Cloudflare Tunnel not connecting

- Verify the tunnel token in Cloudflare Zero Trust dashboard
- Check logs: `docker compose logs cloudflared`
