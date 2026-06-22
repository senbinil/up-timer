# Cloudflare Deployment Guide

Deploy UpTimer behind Cloudflare Tunnel — zero open inbound ports, TLS handled by Cloudflare.

## Why Cloudflare Tunnel

- No ports exposed on the VPS
- Cloudflare handles DDoS protection, TLS termination, and caching
- No certificate management needed
- Works behind NAT/firewalls

## Setup

### 1. Create a Tunnel

1. Go to [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. **Networks** → **Tunnels** → **Create a tunnel**
3. Name it (e.g. `uptimer`)
4. Choose **Docker** as the environment
5. Copy the tunnel token (looks like `eyJ...`)

### 2. Configure Public Hostname

In the tunnel settings, add a public hostname:

| Field | Value |
|---|---|
| Subdomain | `uptime` (or your choice) |
| Domain | `example.com` |
| Service Type | HTTP |
| URL | `up-timer:80` |

### 3. Deploy

```bash
./deploy/installer.sh
# Select: Cloudflare Tunnel
# Paste the tunnel token when prompted
```

Or manually:

```bash
# deploy/.env
CF_TUNNEL_TOKEN=eyJ...

docker compose \
  -f deploy/compose/app.yml \
  -f deploy/tunnel/cloudflared.yml \
  -f deploy/networking/standalone.yml \
  --env-file deploy/.env \
  up -d
```

### How it works

```
Internet → Cloudflare (TLS) → cloudflared (outbound tunnel) → up-timer:80
```

1. `cloudflared` creates an outbound connection to Cloudflare's edge
2. No inbound ports are opened on the VPS
3. Cloudflare terminates TLS and forwards traffic through the tunnel
4. `cloudflared` proxies to `up-timer:80` on the internal Docker network

## Troubleshooting

**Tunnel not connecting:**
```bash
docker compose logs cloudflared
```
Common causes:
- Invalid tunnel token (regenerate from Cloudflare dashboard)
- VPS can't reach Cloudflare (check outbound internet)

**Tunnel connected but 502:**
- Verify the public hostname URL is `up-timer:80` (not localhost)
- Check UpTimer container is running: `docker compose ps`

**Cloudflare SSL mode:**
- Set SSL/TLS mode to **Full** or **Full (strict)** in Cloudflare dashboard
- Flexible SSL may cause redirect loops
