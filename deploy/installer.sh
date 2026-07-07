#!/usr/bin/env bash
# UpTimer Deployment Installer
# Self-contained — no repo clone needed.
#
# One-liner:
#   bash <(curl -sSL https://raw.githubusercontent.com/senbinil/up-timer/main/deploy/installer.sh)
#
# Or save and run:
#   curl -sSLO https://raw.githubusercontent.com/senbinil/up-timer/main/deploy/installer.sh
#   chmod +x installer.sh && ./installer.sh

set -euo pipefail

# Reconnect stdin to the terminal if it was piped (so interactive prompts work)
[ -t 0 ] || exec </dev/tty

# Work from current directory — no dependency on script location
PROJECT_DIR="$(pwd)"
DEPLOY_DIR="$PROJECT_DIR/deploy"
ENV_FILE="$DEPLOY_DIR/.env"
COMPOSE_OUT="$PROJECT_DIR/docker-compose.generated.yml"
NGINX_CONF="$DEPLOY_DIR/nginx.conf"

# Ensure deploy directory exists
mkdir -p "$DEPLOY_DIR"

# ── Colors ──────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }
info() { echo -e "  ${CYAN}→${NC} $1"; }
ask()  { echo -ne "  ${CYAN}?${NC} $1: "; }

# ── Prerequisites ────────────────────────────

check_prereqs() {
    echo ""
    echo -e "${BOLD}Checking prerequisites...${NC}"

    if ! command -v docker &>/dev/null; then
        err "Docker is not installed. Install: https://docs.docker.com/engine/install/"
        exit 1
    fi
    ok "Docker detected"

    if ! docker compose version &>/dev/null; then
        err "Docker Compose plugin is not installed."
        exit 1
    fi
    ok "Docker Compose detected"
}

# ── Detection ────────────────────────────────

detect_environment() {
    echo ""
    echo -e "${BOLD}Detecting environment...${NC}"

    DETECTED_PROXY=""
    DETECTED_NETWORK=""

    # Check for Kamal proxy
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^kamal-proxy$'; then
        DETECTED_PROXY="kamal"
        DETECTED_NETWORK=$(docker inspect kamal-proxy --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}
{{end}}' 2>/dev/null | grep -v '^bridge$' | grep -v '^host$' | grep -v '^none$' | head -1 || echo "")
        if [ -n "$DETECTED_NETWORK" ]; then
            ok "Kamal proxy detected (network: $DETECTED_NETWORK)"
        fi
    fi

    # Check for other Traefik containers
    if [ -z "$DETECTED_PROXY" ]; then
        local traefik_containers
        traefik_containers=$(docker ps --format '{{.Names}} {{.Image}}' 2>/dev/null | grep -i traefik | grep -v uptimer-traefik || true)
        if [ -n "$traefik_containers" ]; then
            local traefik_name
            traefik_name=$(echo "$traefik_containers" | head -1 | awk '{print $1}')
            DETECTED_NETWORK=$(docker inspect "$traefik_name" --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}
{{end}}' 2>/dev/null | grep -v '^bridge$' | grep -v '^host$' | grep -v '^none$' | head -1 || echo "")
            if [ -n "$DETECTED_NETWORK" ]; then
                DETECTED_PROXY="traefik"
                ok "Existing Traefik detected (container: $traefik_name, network: $DETECTED_NETWORK)"
            else
                warn "Traefik found but on default bridge network — can't integrate directly"
                info "Move it to a user-defined network first:"
                info "  docker network create traefik-public"
                info "  docker network connect traefik-public $traefik_name"
            fi
        fi
    fi

    # Check for Nginx containers
    if [ -z "$DETECTED_PROXY" ]; then
        if docker ps --format '{{.Image}}' 2>/dev/null | grep -qi nginx; then
            DETECTED_PROXY="nginx"
            ok "Nginx container detected"
        fi
    fi

    # Check Nginx on host
    if [ -z "$DETECTED_PROXY" ]; then
        if command -v nginx &>/dev/null && systemctl is-active --quiet nginx 2>/dev/null; then
            DETECTED_PROXY="nginx-host"
            ok "Nginx running on host"
        fi
    fi

    if [ -z "$DETECTED_PROXY" ]; then
        info "No existing proxy detected — fresh deployment"
    fi

    # Port checks
    echo ""
    echo -e "${BOLD}Port availability:${NC}"
    local port80_free=true
    local port443_free=true

    if ss -tlnp 2>/dev/null | grep -q ':80 ' || netstat -tlnp 2>/dev/null | grep -q ':80 '; then
        warn "Port 80 is in use"
        port80_free=false
    else
        ok "Port 80 available"
    fi

    if ss -tlnp 2>/dev/null | grep -q ':443 ' || netstat -tlnp 2>/dev/null | grep -q ':443 '; then
        warn "Port 443 is in use"
        port443_free=false
    else
        ok "Port 443 available"
    fi
}

# ── Existing deployment check ────────────────

check_existing_deployment() {
    if [ -f "$ENV_FILE" ] && [ -f "$COMPOSE_OUT" ]; then
        echo ""
        echo -e "${BOLD}Existing deployment detected${NC}"
        source_env "$ENV_FILE"
        info "Domain: ${DOMAIN:-unknown}"
        info "Mode: ${DEPLOY_MODE:-unknown}"
        echo ""
        echo "  1) Update — pull latest image and restart"
        echo "  2) Reconfigure — change settings"
        echo "  3) Uninstall — stop and remove containers"
        echo "  4) Exit"
        echo ""
        read -rp "  Select [1-4]: " existing_choice
        case "$existing_choice" in
            1) update_deployment; exit 0 ;;
            2) info "Starting reconfiguration..."; echo "" ;;
            3) uninstall_deployment; exit 0 ;;
            *) echo "Exiting."; exit 0 ;;
        esac
    fi
}

source_env() {
    local file="$1"
    set -a
    # shellcheck disable=SC1090
    [ -f "$file" ] && . "$file"
    set +a
}

update_deployment() {
    echo ""
    info "Pulling latest image..."
    docker compose -f "$COMPOSE_OUT" pull
    info "Restarting containers..."
    docker compose -f "$COMPOSE_OUT" up -d --remove-orphans
    ok "Deployment updated"
}

uninstall_deployment() {
    echo ""
    warn "This will stop and remove all UpTimer containers."
    read -rp "  Continue? [y/N]: " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Cancelled."
        exit 0
    fi
    docker compose -f "$COMPOSE_OUT" down --volumes --remove-orphans 2>/dev/null || true
    rm -f "$COMPOSE_OUT" "$ENV_FILE" "$NGINX_CONF"
    ok "Deployment removed"
}

# ── Menu ─────────────────────────────────────

show_menu() {
    echo ""
    echo -e "${BOLD}Deployment mode:${NC}"
    echo ""

    local i=1
    OPT_STANDALONE=$i;  echo "  $i) Standalone Traefik + Let's Encrypt (auto HTTPS)"; i=$((i+1))

    if [ "$DETECTED_PROXY" = "kamal" ]; then
        OPT_KAMAL_PROXY=$i; echo -e "  $i) Integrate with existing Kamal Proxy ${GREEN}← auto-detected${NC}"; i=$((i+1))
    else
        OPT_KAMAL_PROXY=$i; echo "  $i) Integrate with existing Kamal Proxy"; i=$((i+1))
    fi

    if [ "$DETECTED_PROXY" = "traefik" ]; then
        OPT_EXISTING_TRAEFIK=$i; echo -e "  $i) Integrate with existing Traefik ${GREEN}← auto-detected${NC}"; i=$((i+1))
    else
        OPT_EXISTING_TRAEFIK=$i; echo "  $i) Integrate with existing Traefik"; i=$((i+1))
    fi

    OPT_NGINX=$i; echo "  $i) Nginx reverse proxy"; i=$((i+1))
    OPT_CLOUDFLARE=$i; echo "  $i) Cloudflare Tunnel (zero open ports)"; i=$((i+1))
    OPT_IP=$i; echo "  $i) IP-only (direct exposure, no proxy)"; i=$((i+1))

    echo ""
    read -rp "  Select [1-$((i-1))]: " mode_choice
    MODE_CHOICE="$mode_choice"
}

# ── Collect env vars ─────────────────────────

collect_env() {
    echo ""
    echo -e "${BOLD}Configuration${NC}"
    echo ""

    # App vars (common)
    read -rp "  Image tag [latest]: " TAG; TAG=${TAG:-latest}

    read -rp "  Admin emails (comma-separated, optional): " ADMIN_EMAILS

    # RAILS_MAX_THREADS auto-detection
    detect_thread_count
    read -rp "  RAILS_MAX_THREADS [3] (auto-detected: $SUGGESTED_THREADS): " RAILS_MAX_THREADS
    RAILS_MAX_THREADS=${RAILS_MAX_THREADS:-3}

    # Email config
    echo ""
    read -rp "  Email provider? [none/resend/mailgun]: " MAIL_PROVIDER
    MAIL_PROVIDER=${MAIL_PROVIDER:-}
    if [ "$MAIL_PROVIDER" = "resend" ]; then
        read -rp "  Resend API key: " RESEND_API_KEY
        read -rp "  Mail from address [noreply@example.com]: " MAIL_FROM
    elif [ "$MAIL_PROVIDER" = "mailgun" ]; then
        read -rp "  Mailgun API key: " MAILGUN_API_KEY
        read -rp "  Mailgun domain: " MAILGUN_DOMAIN
        read -rp "  Mailgun API host [api.mailgun.net]: " MAILGUN_API_HOST
        MAILGUN_API_HOST=\${MAILGUN_API_HOST:-api.mailgun.net}
        read -rp "  Mail from address [noreply@example.com]: " MAIL_FROM
    fi
    MAIL_FROM=${MAIL_FROM:-noreply@example.com}

    # Mode-specific
    case "$MODE" in
        standalone)
            collect_standalone_env
            ;;
        kamal-proxy)
            collect_kamal_proxy_env
            ;;
        existing-traefik)
            collect_existing_traefik_env
            ;;
        nginx)
            collect_nginx_env
            ;;
        cloudflare)
            collect_cloudflare_env
            ;;
        ip-only)
            collect_ip_env
            ;;
    esac

    # Resolve APP_HOST from DOMAIN if not explicitly set (avoids nested expansion in Docker Compose)
    : "${APP_HOST:=${DOMAIN:-}}"

    # Write .env
    write_env_file
}

collect_standalone_env() {
    echo ""
    read -rp "  Domain (e.g. uptime.example.com): " DOMAIN
    while [ -z "$DOMAIN" ]; do
        err "Domain is required"
        read -rp "  Domain: " DOMAIN
    done
    read -rp "  Let's Encrypt email: " LETSENCRYPT_EMAIL
    while [ -z "$LETSENCRYPT_EMAIL" ]; do
        err "Let's Encrypt email is required for certificate notifications"
        read -rp "  Let's Encrypt email: " LETSENCRYPT_EMAIL
    done
    read -rp "  DNS provider [cloudflare]: " DNS_PROVIDER; DNS_PROVIDER=${DNS_PROVIDER:-cloudflare}
    ask "Cloudflare API token (DNS:Edit permission)"
    read -rsp "" CF_DNS_API_TOKEN; echo
    while [ -z "$CF_DNS_API_TOKEN" ]; do
        err "CF_DNS_API_TOKEN is required for DNS challenge"
        ask "Cloudflare API token"
        read -rsp "" CF_DNS_API_TOKEN; echo
    done
    echo ""
    read -rp "  HTTPS only? [Y/n]: " https_choice; https_choice=${https_choice:-y}
    if [ "$https_choice" = "n" ] || [ "$https_choice" = "N" ]; then
        ENTRYPOINT=web
    fi
    DEPLOY_MODE=standalone
}

collect_existing_traefik_env() {
    echo ""
    read -rp "  Domain (e.g. uptime.example.com): " DOMAIN
    while [ -z "$DOMAIN" ]; do
        err "Domain is required"
        read -rp "  Domain: " DOMAIN
    done

    if [ -n "$DETECTED_NETWORK" ]; then
        read -rp "  Traefik network [$DETECTED_NETWORK]: " TRAEFIK_NETWORK
        TRAEFIK_NETWORK=${TRAEFIK_NETWORK:-$DETECTED_NETWORK}
    else
        read -rp "  Traefik Docker network name: " TRAEFIK_NETWORK
        while [ -z "$TRAEFIK_NETWORK" ]; do
            err "Network name is required"
            read -rp "  Traefik Docker network name: " TRAEFIK_NETWORK
        done
    fi

    # Reject Docker built-in networks
    while [ "$TRAEFIK_NETWORK" = "bridge" ] || [ "$TRAEFIK_NETWORK" = "host" ] || [ "$TRAEFIK_NETWORK" = "none" ]; do
        err "Cannot use Docker built-in network '$TRAEFIK_NETWORK' — must use a user-defined network"
        info "Create one with: docker network create traefik-public"
        read -rp "  Traefik Docker network name: " TRAEFIK_NETWORK
        while [ -z "$TRAEFIK_NETWORK" ]; do
            read -rp "  Traefik Docker network name: " TRAEFIK_NETWORK
        done
    done

    # Validate network exists
    while ! docker network ls --format '{{.Name}}' 2>/dev/null | grep -qx "$TRAEFIK_NETWORK"; do
        err "Network '$TRAEFIK_NETWORK' not found"
        echo "  Existing networks:"
        docker network ls --format '    {{.Name}}' | grep -v '^bridge$' | grep -v '^host$' | grep -v '^none$'
        read -rp "  Traefik Docker network name (or enter 'create' to make one): " TRAEFIK_NETWORK
        if [ "$TRAEFIK_NETWORK" = "create" ]; then
            read -rp "  New network name: " TRAEFIK_NETWORK
            docker network create "$TRAEFIK_NETWORK" && ok "Created network: $TRAEFIK_NETWORK" || err "Failed to create network"
        fi
    done

    read -rp "  HTTPS only? [Y/n]: " https_choice; https_choice=${https_choice:-y}
    if [ "$https_choice" = "n" ] || [ "$https_choice" = "N" ]; then
        ENTRYPOINT=web
    fi
    DEPLOY_MODE=existing-traefik
}

collect_kamal_proxy_env() {
    echo ""
    read -rp "  Domain (e.g. uptime.example.com): " DOMAIN
    while [ -z "$DOMAIN" ]; do
        err "Domain is required"
        read -rp "  Domain: " DOMAIN
    done

    if [ -n "$DETECTED_NETWORK" ]; then
        read -rp "  Kamal network [$DETECTED_NETWORK]: " TRAEFIK_NETWORK
        TRAEFIK_NETWORK=${TRAEFIK_NETWORK:-$DETECTED_NETWORK}
    else
        read -rp "  Kamal Docker network name: " TRAEFIK_NETWORK
        while [ -z "$TRAEFIK_NETWORK" ]; do
            err "Network name is required"
            read -rp "  Kamal Docker network name: " TRAEFIK_NETWORK
        done
    fi

    # Reject Docker built-in networks
    while [ "$TRAEFIK_NETWORK" = "bridge" ] || [ "$TRAEFIK_NETWORK" = "host" ] || [ "$TRAEFIK_NETWORK" = "none" ]; do
        err "Cannot use Docker built-in network '$TRAEFIK_NETWORK' — must use a user-defined network"
        read -rp "  Kamal Docker network name: " TRAEFIK_NETWORK
        while [ -z "$TRAEFIK_NETWORK" ]; do
            read -rp "  Kamal Docker network name: " TRAEFIK_NETWORK
        done
    done

    # Validate network exists
    while ! docker network ls --format '{{.Name}}' 2>/dev/null | grep -qx "$TRAEFIK_NETWORK"; do
        err "Network '$TRAEFIK_NETWORK' not found"
        echo "  Existing networks:"
        docker network ls --format '    {{.Name}}' | grep -v '^bridge$' | grep -v '^host$' | grep -v '^none$'
        read -rp "  Kamal Docker network name (or enter 'create' to make one): " TRAEFIK_NETWORK
        if [ "$TRAEFIK_NETWORK" = "create" ]; then
            read -rp "  New network name: " TRAEFIK_NETWORK
            docker network create "$TRAEFIK_NETWORK" && ok "Created network: $TRAEFIK_NETWORK" || err "Failed to create network"
        fi
    done

    read -rp "  Enable automatic HTTPS via Let's Encrypt? [Y/n]: " https_choice; https_choice=${https_choice:-y}
    if [ "$https_choice" = "y" ] || [ "$https_choice" = "Y" ]; then
        KAMAL_PROXY_TLS=true
    else
        KAMAL_PROXY_TLS=false
    fi
    DEPLOY_MODE=kamal-proxy
}

collect_nginx_env() {
    echo ""
    read -rp "  Domain (e.g. uptime.example.com): " DOMAIN
    while [ -z "$DOMAIN" ]; do
        err "Domain is required"
        read -rp "  Domain: " DOMAIN
    done
    DEPLOY_MODE=nginx
}

collect_cloudflare_env() {
    echo ""
    read -rp "  Domain (e.g. uptime.example.com): " DOMAIN
    while [ -z "$DOMAIN" ]; do
        err "Domain is required"
        read -rp "  Domain: " DOMAIN
    done
    read -rp "  Upstream service URL [http://up-timer:80]: " SERVICE_URL
    SERVICE_URL=${SERVICE_URL:-http://up-timer:80}
    ask "Cloudflare tunnel token"
    read -rsp "" CF_TUNNEL_TOKEN; echo
    while [ -z "$CF_TUNNEL_TOKEN" ]; do
        err "Tunnel token is required"
        ask "Cloudflare tunnel token"
        read -rsp "" CF_TUNNEL_TOKEN; echo
    done
    DEPLOY_MODE=cloudflare
}

collect_ip_env() {
    echo ""
    read -rp "  Host port to bind [80]: " APP_PORT; APP_PORT=${APP_PORT:-80}
    DEPLOY_MODE=ip-only
}

# ── RAILS_MAX_THREADS auto-detection ──────────

detect_thread_count() {
    local ram_mb=1024
    local cpu_cores=1

    if command -v free &>/dev/null; then
        ram_mb=$(free -m 2>/dev/null | awk '/Mem:/ {print $7}' || echo 1024)
    fi

    if command -v nproc &>/dev/null; then
        cpu_cores=$(nproc 2>/dev/null || echo 1)
    fi

    # Reserve ~512MB for OS + Puma, assume ~100MB per thread
    local by_ram=$(( (ram_mb - 512) / 100 ))
    if [ "$by_ram" -lt 0 ]; then by_ram=0; fi

    # Cap by CPU (4 threads per core is a practical CRuby limit)
    local by_cpu=$((cpu_cores * 4))

    SUGGESTED_THREADS=$(( by_ram < by_cpu ? by_ram : by_cpu ))

    # Clamp between 3 and 16
    if [ "$SUGGESTED_THREADS" -lt 3 ]; then SUGGESTED_THREADS=3; fi
    if [ "$SUGGESTED_THREADS" -gt 16 ]; then SUGGESTED_THREADS=16; fi
}

# ── Write .env ───────────────────────────────

write_env_file() {
    cat > "$ENV_FILE" << EOF
# UpTimer deployment configuration
# Generated by deploy/installer.sh on $(date)

# App
TAG=${TAG}
RAILS_MASTER_KEY=${RAILS_MASTER_KEY:-}
RAILS_MAX_THREADS=${RAILS_MAX_THREADS:-3}
ADMIN_EMAILS=${ADMIN_EMAILS:-}
APP_HOST=${APP_HOST:-}
MAIL_PROVIDER=${MAIL_PROVIDER:-}
MAIL_FROM=${MAIL_FROM:-noreply@example.com}
RESEND_API_KEY=${RESEND_API_KEY:-}
MAILGUN_API_KEY=${MAILGUN_API_KEY:-}
MAILGUN_API_HOST=${MAILGUN_API_HOST:-}
MAILGUN_DOMAIN=${MAILGUN_DOMAIN:-}
DOMAIN=${DOMAIN:-}
TRAEFIK_NETWORK=${TRAEFIK_NETWORK:-}
ENTRYPOINT=${ENTRYPOINT:-websecure}
DEPLOY_MODE=${DEPLOY_MODE}
EOF

    # Mode-specific vars
    case "$MODE" in
        standalone)
            cat >> "$ENV_FILE" << EOF
LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
DNS_PROVIDER=${DNS_PROVIDER:-cloudflare}
CF_DNS_API_TOKEN=${CF_DNS_API_TOKEN}
EOF
            ;;
        existing-traefik)
            cat >> "$ENV_FILE" << EOF
TRAEFIK_NETWORK=${TRAEFIK_NETWORK}
EOF
            ;;
        kamal-proxy)
            cat >> "$ENV_FILE" << EOF
TRAEFIK_NETWORK=${TRAEFIK_NETWORK}
KAMAL_PROXY_TLS=${KAMAL_PROXY_TLS:-true}
EOF
            ;;
        cloudflare)
            cat >> "$ENV_FILE" << EOF
DOMAIN=${DOMAIN}
CF_TUNNEL_TOKEN=${CF_TUNNEL_TOKEN}
SERVICE_URL=${SERVICE_URL:-http://up-timer:80}
EOF
            ;;
        ip-only)
            cat >> "$ENV_FILE" << EOF
APP_PORT=${APP_PORT:-80}
EOF
            ;;
    esac

    ok "Config saved to deploy/.env"
}

# ── Generate compose file ────────────────────

# Shared app service (defined once — change here for DB migrations, env vars, etc.)
write_app_service() {
    # Usage: write_app_service [with_ports] [with_labels]
    cat << 'END_APP'
  up-timer:
    image: binilsn/up-timer:${TAG:-latest}
END_APP
    if [ "${1:-}" = "with_ports" ]; then
        cat << 'END_PORTS'
    ports:
      - "${APP_PORT:-80}:80"
END_PORTS
    fi
    cat << 'END_APP_ENV'
    environment:
      - RAILS_ENV=production
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
      - RAILS_MAX_THREADS=${RAILS_MAX_THREADS:-3}
      - SOLID_QUEUE_IN_PUMA=true
      - APP_HOST=${APP_HOST}
      - ADMIN_EMAILS=${ADMIN_EMAILS:-}
      - MAIL_PROVIDER=${MAIL_PROVIDER:-}
      - MAIL_FROM=${MAIL_FROM:-noreply@example.com}
      - RESEND_API_KEY=${RESEND_API_KEY:-}
      - MAILGUN_API_KEY=${MAILGUN_API_KEY:-}
      - MAILGUN_API_HOST=${MAILGUN_API_HOST:-}
      - MAILGUN_DOMAIN=${MAILGUN_DOMAIN:-}
    volumes:
      - up-timer-storage:/rails/storage
      - up-timer-db:/rails/db
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/up"]
      interval: 10s
      timeout: 3s
      retries: 3
    restart: unless-stopped
    networks:
      - web
END_APP_ENV
    if [ "${2:-}" = "with_labels" ]; then
        cat << 'END_LABELS'
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.uptimer.rule=Host(`${DOMAIN}`)"
      - "traefik.http.routers.uptimer.entrypoints=${ENTRYPOINT:-websecure}"
      - "traefik.http.routers.uptimer.tls.certresolver=letsencrypt"
END_LABELS
    fi
}

# Shared volumes
write_common_volumes() {
    cat << 'END_VOL'
  up-timer-storage:
  up-timer-db:
END_VOL
}

generate_compose() {
    echo ""
    info "Generating docker-compose file..."

    # Header
    cat > "$COMPOSE_OUT" << HEADER
# Generated by deploy/installer.sh — do not edit directly.
# To reconfigure, run the installer again.
#
# Deployment mode: $DEPLOY_MODE

HEADER

    # Assemble from shared functions + scenario-specific pieces
    case "$MODE" in
        standalone)
            cat >> "$COMPOSE_OUT" << 'END'
services:
END
            write_app_service "" "with_labels" >> "$COMPOSE_OUT"
            cat >> "$COMPOSE_OUT" << 'END'

  traefik:
    image: traefik:v3
    container_name: uptimer-traefik
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik-certs:/letsencrypt
    environment:
      - CF_DNS_API_TOKEN=${CF_DNS_API_TOKEN}
    command:
      - "--global.sendAnonymousUsage=false"
      - "--api.dashboard=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      - "--entrypoints.websecure.address=:443"
      - "--providers.docker"
      - "--certificatesresolvers.letsencrypt.acme.email=${LETSENCRYPT_EMAIL}"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=${DNS_PROVIDER:-cloudflare}"
    restart: unless-stopped
    networks:
      - web

volumes:
END
            write_common_volumes >> "$COMPOSE_OUT"
            cat >> "$COMPOSE_OUT" << 'END'
  traefik-certs:

networks:
  web:
    driver: bridge
END
            ;;
        kamal-proxy)
            cat >> "$COMPOSE_OUT" << 'END'
services:
END
            write_app_service "" "" >> "$COMPOSE_OUT"
            cat >> "$COMPOSE_OUT" << 'END'

volumes:
END
            write_common_volumes >> "$COMPOSE_OUT"
            cat >> "$COMPOSE_OUT" << 'END'

networks:
  web:
    external: true
    name: ${TRAEFIK_NETWORK}
END
            ;;
        existing-traefik)
            cat >> "$COMPOSE_OUT" << 'END'
services:
END
            write_app_service "" "with_labels" >> "$COMPOSE_OUT"
            cat >> "$COMPOSE_OUT" << 'END'

volumes:
END
            write_common_volumes >> "$COMPOSE_OUT"
            cat >> "$COMPOSE_OUT" << 'END'

networks:
  web:
    external: true
    name: ${TRAEFIK_NETWORK}
END
            ;;
        nginx)
            cat >> "$COMPOSE_OUT" << 'END'
services:
END
            write_app_service "" "" >> "$COMPOSE_OUT"
            cat >> "$COMPOSE_OUT" << 'END'

  nginx:
    image: nginx:alpine
    container_name: uptimer-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./deploy/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - nginx-certs:/etc/nginx/certs
    depends_on:
      - up-timer
    restart: unless-stopped
    networks:
      - web

volumes:
END
            write_common_volumes >> "$COMPOSE_OUT"
            cat >> "$COMPOSE_OUT" << 'END'
  nginx-certs:

networks:
  web:
    driver: bridge
END
            # Generate nginx config from embedded template
            cat > "$NGINX_CONF" << NGINX
server {
    listen 80;
    server_name ${DOMAIN:-localhost};
    client_max_body_size 50M;

    location / {
        proxy_pass http://up-timer:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /up {
        proxy_pass http://up-timer:80;
        proxy_set_header Host \$host;
    }
}
NGINX
            ok "Generated deploy/nginx.conf"
            ;;
        cloudflare)
            # Generate cloudflared config file
            CLOUDFLARED_CONFIG="$DEPLOY_DIR/cloudflared.yml"
            cat > "$CLOUDFLARED_CONFIG" << CLOUDCONF
# Generated by deploy/installer.sh
# Tunnel token is passed via environment variable (TUNNEL_TOKEN)

# Ingress rules: route the domain to the upstream service
# See https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/install-and-setup/tunnel-guide/local/local-management/ingress/
ingress:
  - hostname: ${DOMAIN}
    service: ${SERVICE_URL:-http://up-timer:80}
  # Catch-all: return 404 for unknown hostnames
  - service: http_status:404
CLOUDCONF
            ok "Generated deploy/cloudflared.yml"

            cat >> "$COMPOSE_OUT" << 'END'
services:
END
            write_app_service "" "" >> "$COMPOSE_OUT"
            cat >> "$COMPOSE_OUT" << 'END'

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: uptimer-tunnel
    command: tunnel --config /etc/cloudflared/config.yml run
    environment:
      - TUNNEL_TOKEN=${CF_TUNNEL_TOKEN}
    volumes:
      - ./deploy/cloudflared.yml:/etc/cloudflared/config.yml:ro
    restart: unless-stopped
    networks:
      - web

volumes:
END
            write_common_volumes >> "$COMPOSE_OUT"
            cat >> "$COMPOSE_OUT" << 'END'

networks:
  web:
    driver: bridge
END
            ;;
        ip-only)
            cat >> "$COMPOSE_OUT" << 'END'
services:
END
            write_app_service "with_ports" "" >> "$COMPOSE_OUT"
            cat >> "$COMPOSE_OUT" << 'END'

volumes:
END
            write_common_volumes >> "$COMPOSE_OUT"
            cat >> "$COMPOSE_OUT" << 'END'

networks:
  web:
    driver: bridge
END
            ;;
    esac

    ok "Generated docker-compose.generated.yml"
}

# ── Deploy ───────────────────────────────────

deploy() {
    echo ""
    echo -e "${BOLD}Deploy summary:${NC}"
    echo "  Mode:      $DEPLOY_MODE"
    if [ -n "${DOMAIN:-}" ]; then echo "  Domain:    $DOMAIN"; fi
    if [ -n "${TAG:-}" ]; then echo "  Image tag: $TAG"; fi
    echo ""

    read -rp "  Start containers now? [Y/n]: " deploy_confirm
    deploy_confirm=${deploy_confirm:-y}
    if [ "$deploy_confirm" = "n" ] || [ "$deploy_confirm" = "N" ]; then
        echo ""
        info "To start later, run:"
        echo ""
        echo "  docker compose -f docker-compose.generated.yml --env-file deploy/.env up -d"
        echo ""
        exit 0
    fi

    echo ""
    info "Starting containers..."

    cd "$PROJECT_DIR"
    docker compose -f "$COMPOSE_OUT" --env-file "$ENV_FILE" up -d

    if [ "$DEPLOY_MODE" = "kamal-proxy" ] && [ -n "${DOMAIN:-}" ]; then
        echo ""
        info "Registering route with kamal-proxy..."
        local tls_flag=""
        if [ "${KAMAL_PROXY_TLS:-true}" = "true" ]; then
            tls_flag="--tls"
        fi
        docker exec kamal-proxy kamal-proxy deploy up-timer \
            --target up-timer:80 \
            --host "$DOMAIN" \
            $tls_flag \
            --health-check-path /up && \
            ok "Route registered: $DOMAIN → up-timer:80" || \
            warn "Route registration failed — you may need to run it manually"
    fi

    echo ""
    ok "Deployment complete!"
    if [ -n "${DOMAIN:-}" ]; then
        echo ""
        echo "  Your UpTimer instance will be available at:"
        if [ "$DEPLOY_MODE" = "kamal-proxy" ] && [ "${KAMAL_PROXY_TLS:-true}" = "true" ]; then
            echo -e "  ${BOLD}https://${DOMAIN}${NC}"
        elif [ "$DEPLOY_MODE" = "kamal-proxy" ]; then
            echo -e "  ${BOLD}http://${DOMAIN}${NC}"
        else
            echo -e "  ${BOLD}https://${DOMAIN}${NC}"
        fi
    fi
    echo ""
    echo "  Check status:  docker compose -f docker-compose.generated.yml ps"
    echo "  View logs:     docker compose -f docker-compose.generated.yml logs -f"
    echo "  Update:        ./deploy/installer.sh"
}

# ── Determine mode from choice ───────────────

resolve_mode() {
    if [ "$MODE_CHOICE" = "$OPT_STANDALONE" ]; then
        MODE=standalone
    elif [ "$MODE_CHOICE" = "$OPT_KAMAL_PROXY" ]; then
        MODE=kamal-proxy
    elif [ "$MODE_CHOICE" = "$OPT_EXISTING_TRAEFIK" ]; then
        MODE=existing-traefik
    elif [ "$MODE_CHOICE" = "$OPT_NGINX" ]; then
        MODE=nginx
    elif [ "$MODE_CHOICE" = "$OPT_CLOUDFLARE" ]; then
        MODE=cloudflare
    elif [ "$MODE_CHOICE" = "$OPT_IP" ]; then
        MODE=ip-only
    else
        err "Invalid choice"
        exit 1
    fi
}

# ── Main ─────────────────────────────────────

main() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════╗${NC}"
    echo -e "${BOLD}║   UpTimer Deployment Installer   ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════╝${NC}"

    check_prereqs
    detect_environment
    check_existing_deployment
    show_menu
    resolve_mode
    collect_env
    generate_compose
    deploy
}

main "$@"
