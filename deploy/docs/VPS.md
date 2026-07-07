# VPS Deployment Guide

General setup for deploying UpTimer on any Linux VPS.

## Prerequisites

- Linux VPS (Ubuntu 22.04+ recommended)
- Docker + Docker Compose installed
- A domain name pointed to the VPS IP (or Cloudflare Tunnel token)

## Install Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and back in
```

## Quick Deploy

**One-liner (no clone needed):**

```bash
curl -sSL https://raw.githubusercontent.com/senbinil/up-timer/main/deploy/installer.sh | bash
```

**From a cloned repo:**

```bash
git clone https://github.com/senbinil/up-timer.git
cd up-timer
./deploy/installer.sh
```

## Coexistence with Kamal

If Kamal is already deployed on this VPS:

1. The installer auto-detects the `kamal-proxy` container
2. Select **Existing Traefik** integration
3. UpTimer attaches to Kamal's Docker network
4. No port conflicts — both apps share the same Traefik

## Firewall

Only open ports that your deployment mode needs:

```bash
# Standalone Traefik
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Cloudflare Tunnel — no ports needed!
# IP-only
sudo ufw allow 80/tcp
```

## Systemd Auto-Start

Docker Compose services with `restart: unless-stopped` restart on boot automatically if the Docker daemon is enabled:

```bash
sudo systemctl enable docker
```

## Updating

```bash
./deploy/installer.sh
# Select "Update" from the menu
```

Or set up a cron job for auto-updates:

```bash
# /etc/cron.d/uptimer-update
0 3 * * * root cd /path/to/up-timer && docker compose -f docker-compose.generated.yml --env-file deploy/.env pull && docker compose -f docker-compose.generated.yml --env-file deploy/.env up -d --remove-orphans
```

Note: auto-updating `latest` tag can pull breaking changes. Pin a version tag in `.env` for production.

## Backups

SQLite database and uploads are stored in Docker volumes.

Volume names follow the pattern `<directory>_<volume>` (e.g. `up-timer_up-timer-db`).
Run `docker volume ls | grep up-timer` to confirm.

```bash
# Backup
docker run --rm -v up-timer_up-timer-db:/data -v $(pwd)/backups:/backup alpine tar czf /backup/up-timer-$(date +%Y%m%d).tar.gz -C /data .

# Restore
docker run --rm -v up-timer_up-timer-db:/data -v $(pwd)/backups:/backup alpine tar xzf /backup/up-timer-20260101.tar.gz -C /data
```
