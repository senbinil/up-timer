#!/usr/bin/env bash
# UpTimer Deployment Installer
# Self-contained — no repo clone needed.
#
# One-liner:
#   curl -sSL https://raw.githubusercontent.com/binilsn/up-timer/main/deploy/installer.sh | bash
#
# Or save and run:
#   curl -sSLO https://raw.githubusercontent.com/binilsn/up-timer/main/deploy/installer.sh
#   chmod +x installer.sh && ./installer.sh

set -euo pipefail

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
        # Find which network kamal-proxy is on
        DETECTED_NETWORK=$(docker inspect kamal-proxy --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>/dev/null || echo "kamal")
        ok "Kamal proxy detected (network: $DETECTED_NETWORK)"
    fi

    # Check for other Traefik containers
    if [ -z "$DETECTED_PROXY" ]; then
        local traefik_containers
        traefik_containers=$(docker ps --format '{{.Names}} {{.Image}}' 2>/dev/null | grep -i traefik | grep -v uptimer-traefik || true)
        if [ -n "$traefik_containers" ]; then
            DETECTED_PROXY="traefik"
            local traefik_name
            traefik_name=$(echo "$traefik_containers" | head -1 | awk '{print $1}')
            DETECTED_NETWORK=$(docker inspect "$traefik_name" --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>/dev/null || echo "traefik-public")
            ok "Existing Traefik detected (container: $traefik_name, network: $DETECTED_NETWORK)"
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

    if [ "$DETECTED_PROXY" = "kamal" ] || [ "$DETECTED_PROXY" = "traefik" ]; then
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
        read -rp "  Mail from address [noreply@example.com]: " MAIL_FROM
    fi
    MAIL_FROM=${MAIL_FROM:-noreply@example.com}

    # Mode-specific
    case "$MODE" in
        standalone)
            collect_standalone_env
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

    read -rp "  HTTPS only? [Y/n]: " https_choice; https_choice=${https_choice:-y}
    if [ "$https_choice" = "n" ] || [ "$https_choice" = "N" ]; then
        ENTRYPOINT=web
    fi
    DEPLOY_MODE=existing-traefik
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

# ── Write .env ───────────────────────────────

write_env_file() {
    cat > "$ENV_FILE" << EOF
# UpTimer deployment configuration
# Generated by deploy/installer.sh on $(date)

# App
TAG=${TAG}
RAILS_MASTER_KEY=${RAILS_MASTER_KEY:-}
ADMIN_EMAILS=${ADMIN_EMAILS:-}
APP_HOST=${APP_HOST:-}
MAIL_PROVIDER=${MAIL_PROVIDER:-}
MAIL_FROM=${MAIL_FROM:-noreply@example.com}
RESEND_API_KEY=${RESEND_API_KEY:-}
MAILGUN_API_KEY=${MAILGUN_API_KEY:-}
MAILGUN_DOMAIN=${MAILGUN_DOMAIN:-}
DOMAIN=${DOMAIN:-}
DEPLOY_MODE=${DEPLOY_MODE}
EOF

    # Mode-specific vars
    case "$MODE" in
        standalone)
            cat >> "$ENV_FILE" << EOF
LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
DNS_PROVIDER=${DNS_PROVIDER:-cloudflare}
CF_DNS_API_TOKEN=${CF_DNS_API_TOKEN}
ENTRYPOINT=${ENTRYPOINT:-websecure}
EOF
            ;;
        existing-traefik)
            cat >> "$ENV_FILE" << EOF
TRAEFIK_NETWORK=${TRAEFIK_NETWORK}
ENTRYPOINT=${ENTRYPOINT:-websecure}
EOF
            ;;
        cloudflare)
            cat >> "$ENV_FILE" << EOF
CF_TUNNEL_TOKEN=${CF_TUNNEL_TOKEN}
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
      - SOLID_QUEUE_IN_PUMA=true
      - APP_HOST=${APP_HOST:-${DOMAIN}}
      - ADMIN_EMAILS=${ADMIN_EMAILS:-}
      - MAIL_PROVIDER=${MAIL_PROVIDER:-}
      - MAIL_FROM=${MAIL_FROM:-noreply@example.com}
      - RESEND_API_KEY=${RESEND_API_KEY:-}
      - MAILGUN_API_KEY=${MAILGUN_API_KEY:-}
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
            cat >> "$COMPOSE_OUT" << 'END'
services:
END
            write_app_service "" "" >> "$COMPOSE_OUT"
            cat >> "$COMPOSE_OUT" << 'END'

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: uptimer-tunnel
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${CF_TUNNEL_TOKEN}
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
    [ -n "${DOMAIN:-}" ] && echo "  Domain:    $DOMAIN"
    [ -n "${TAG:-}" ] && echo "  Image tag: $TAG"
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

    echo ""
    ok "Deployment complete!"
    if [ -n "${DOMAIN:-}" ]; then
        echo ""
        echo "  Your UpTimer instance will be available at:"
        echo -e "  ${BOLD}https://${DOMAIN}${NC}"
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
