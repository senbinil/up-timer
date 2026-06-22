# Nginx Deployment Guide

Use Nginx as a reverse proxy when it's already running on the host or you prefer Nginx over Traefik.

## Standalone Nginx

The installer creates a new Nginx container that routes to UpTimer.

```bash
./deploy/installer.sh
# Select: Standalone Nginx
```

### How it works

1. Nginx container binds ports 80 and 443
2. `deploy/nginx.conf` is generated from `templates/nginx.conf` with your domain
3. Nginx proxies requests to `up-timer:80` on the internal Docker network
4. Traffic: `Internet → Nginx → up-timer (HTTP:80)`

### Generated Config

The installer substitutes `__DOMAIN__` in the template:

```nginx
server {
    listen 80;
    server_name uptime.example.com;

    location / {
        proxy_pass http://up-timer:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Adding SSL

The standalone Nginx config is HTTP-only by default. To add HTTPS:

1. Obtain certificates (Let's Encrypt certbot or Cloudflare Origin)
2. Place certs in a volume mounted at `/etc/nginx/certs`
3. Update `deploy/nginx.conf` to add the SSL server block
4. Restart: `docker compose restart nginx`

## Existing Nginx on Host

When Nginx is installed directly on the VPS (not in Docker):

1. Add a vhost that proxies to the UpTimer container:

```nginx
server {
    listen 80;
    server_name uptime.example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;  # or whichever port you bind
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

2. Deploy UpTimer in IP-only mode with a custom port:

```bash
APP_PORT=8080 docker compose -f deploy/compose/app-ip.yml -f deploy/networking/standalone.yml --env-file deploy/.env up -d
```

3. Reload Nginx: `sudo nginx -s reload`

## Troubleshooting

**502 Bad Gateway:**
- UpTimer container not running: `docker compose ps`
- Nginx can't resolve `up-timer`: check they're on the same Docker network

**Nginx config not loading:**
```bash
docker compose exec nginx nginx -t   # Test config
docker compose restart nginx          # Apply changes
```
