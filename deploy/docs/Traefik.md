# Traefik Deployment Guide

Traefik is a modern reverse proxy with automatic Let's Encrypt certificate management.

## Standalone Traefik

Use this when Traefik is NOT already running. The installer creates a new Traefik container.

```bash
./deploy/installer.sh
# Select: Standalone Traefik + Let's Encrypt
```

### How it works

1. Traefik container binds ports 80 and 443
2. Traefik watches Docker for new containers via the Docker socket
3. When `up-timer` starts, Traefik reads its labels and creates a route
4. Traefik requests a Let's Encrypt certificate via DNS challenge
5. Traffic: `Internet → Traefik (HTTPS) → up-timer (HTTP:80)`

### Certificate Renewal

Let's Encrypt certificates renew automatically 30 days before expiry. No manual intervention needed.

### DNS Providers

The installer uses Cloudflare by default. For other providers, set `DNS_PROVIDER` in `.env`.

Supported providers: [Traefik ACME DNS Challenge Docs](https://doc.traefik.io/traefik/https/acme/#dnschallenge)

### TLS Configuration

| ENTRYPOINT | Behavior |
|---|---|
| `websecure` (default) | HTTPS only, HTTP redirects to HTTPS |
| `web` | HTTP only (use with Cloudflare SSL) |

## Existing Traefik

Use this when Traefik is already running (e.g. from Kamal or a previous setup).

```bash
./deploy/installer.sh
# Auto-detected → Select: Integrate with existing Traefik
```

### How it works

1. No new Traefik container — only labels are added to `up-timer`
2. UpTimer attaches to the existing Traefik's Docker network
3. The existing Traefik discovers the container and routes traffic

### Network Auto-Detection

The installer checks for running Traefik containers and their networks:

| Container | Detected Network |
|---|---|
| `kamal-proxy` | `kamal` |
| `traefik` | Whatever network it's on |

### Troubleshooting

**Certificate not issued:**
```bash
docker compose logs traefik | grep -i error
```
Common issues:
- DNS not pointing to server
- `CF_DNS_API_TOKEN` missing DNS:Edit permission
- Rate limiting (5 certs/week per domain with Let's Encrypt staging)

**Route not working (existing Traefik):**
- Verify both containers are on the same Docker network: `docker network inspect <name>`
- Check Traefik dashboard to see if the router was discovered
