#!/usr/bin/env bash
# Integration test: verifies .env → docker-compose → resolved output pipeline.
# Requires Docker daemon (uses `docker compose config` — no containers started).

set -eo pipefail

TESTS_RAN=0
TESTS_PASSED=0
TEST_DIR=""
COMPOSE_PATH=""
ENV_PATH=""

# ── Colors ───────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); TESTS_RAN=$((TESTS_RAN + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; TESTS_RAN=$((TESTS_RAN + 1)); }

# ── Import compose generation ────────────────
COMPOSE_OUT=""
DEPLOY_DIR=""
NGINX_CONF=""
PROJECT_DIR=""

eval "$(sed -n '/^write_app_service/,/^main()/p' deploy/installer.sh | head -n -2)"

ok()   { true; }
info() { true; }
warn() { true; }

# ── Helpers ──────────────────────────────────

setup() {
    TEST_DIR=$(mktemp -d)
    COMPOSE_PATH="$TEST_DIR/docker-compose.yml"
    ENV_PATH="$TEST_DIR/.env"
    DEPLOY_DIR="$TEST_DIR"
    NGINX_CONF="$TEST_DIR/nginx.conf"
    COMPOSE_OUT="$COMPOSE_PATH"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# Generate compose file for a mode, populating .env alongside
generate() {
    local mode="$1"; shift

    # Set env defaults for generation
    export TAG="${TAG:-latest}"
    export DOMAIN="${DOMAIN:-integration.example.com}"
    export APP_HOST="${APP_HOST:-$DOMAIN}"
    export RAILS_MAX_THREADS="${RAILS_MAX_THREADS:-3}"
    export TRAEFIK_NETWORK="${TRAEFIK_NETWORK:-kamal}"
    export ENTRYPOINT="${ENTRYPOINT:-websecure}"
    export APP_PORT="${APP_PORT:-80}"
    export SERVICE_URL="${SERVICE_URL:-http://up-timer:80}"
    export DEPLOY_MODE="$mode"
    export COMPOSE_OUT="$COMPOSE_PATH"
    export DEPLOY_DIR="$TEST_DIR"
    export NGINX_CONF="$TEST_DIR/nginx.conf"

    # Apply overrides
    for pair in "$@"; do
        local var="${pair%%=*}" val="${pair#*=}"
        export "$var"="$val"
    done

    # Resolve APP_HOST from DOMAIN if not explicitly set (matches collect_env)
    : "${APP_HOST:=${DOMAIN:-}}"

    MODE="$mode"
    generate_compose 2>/dev/null || true

    # Write corresponding .env file (simulates what write_env_file does)
    cat > "$ENV_PATH" << EOF
TAG=${TAG}
SECRET_KEY_BASE=${SECRET_KEY_BASE:-}
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
    # Append mode-specific vars
    case "$DEPLOY_MODE" in
        cloudflare)
            cat >> "$ENV_PATH" << EOF
CF_TUNNEL_TOKEN=${CF_TUNNEL_TOKEN:-}
EOF
            ;;
        ip-only)
            cat >> "$ENV_PATH" << EOF
APP_PORT=${APP_PORT:-80}
EOF
            ;;
    esac

    unset TAG DOMAIN APP_HOST RAILS_MAX_THREADS TRAEFIK_NETWORK ENTRYPOINT DEPLOY_MODE MODE APP_PORT SERVICE_URL DEPLOY_DIR NGINX_CONF COMPOSE_OUT
}

# Run docker compose config and grep the resolved output
assert_resolved() {
    local label="$1" pattern="$2" mode="${3:-}"
    local config_out="$TEST_DIR/resolved.yml"

    if ! docker compose -f "$COMPOSE_PATH" --env-file "$ENV_PATH" config 2>"$TEST_DIR/docker_err.txt" > "$config_out"; then
        fail "$label — docker compose config failed"
        cat "$TEST_DIR/docker_err.txt" | sed 's/^/    /'
        return
    fi

    if grep -q "$pattern" "$config_out"; then
        pass "$label"
    else
        fail "$label — pattern '$pattern' not found in resolved config"
        echo "    Resolved config (first 15 lines):"
        head -15 "$config_out" | sed 's/^/      /'
    fi
}

assert_resolved_not() {
    local label="$1" pattern="$2" mode="${3:-}"
    local config_out="$TEST_DIR/resolved.yml"

    if ! docker compose -f "$COMPOSE_PATH" --env-file "$ENV_PATH" config 2>"$TEST_DIR/docker_err.txt" > "$config_out"; then
        fail "$label — docker compose config failed"
        return
    fi

    if grep -q "$pattern" "$config_out"; then
        fail "$label — unexpected pattern '$pattern' found"
        grep "$pattern" "$config_out" | head -3 | sed 's/^/    /'
    else
        pass "$label"
    fi
}

summary() {
    echo ""
    echo -e "${BOLD}Results:${NC} $TESTS_PASSED/$TESTS_RAN passed"
    [ "$TESTS_PASSED" -eq "$TESTS_RAN" ]
}

# ── Tests ────────────────────────────────────

test_image_tag_resolved_from_env() {
    setup; generate "kamal-proxy" "TAG=v2.0.0"
    assert_resolved "image tag resolves to v2.0.0" "image: binilsn/up-timer:v2.0.0"
    teardown
}

test_image_tag_default_latest() {
    setup; generate "kamal-proxy"
    assert_resolved "image tag defaults to latest" "image: binilsn/up-timer:latest"
    teardown
}

test_app_host_resolved_from_domain() {
    setup; generate "kamal-proxy" "DOMAIN=myapp.example.com" "APP_HOST="
    assert_resolved "APP_HOST resolves to DOMAIN when not set" "APP_HOST: myapp.example.com"
    teardown
}

test_app_host_explicit_value() {
    setup; generate "kamal-proxy" "DOMAIN=myapp.example.com" "APP_HOST=custom.example.com"
    assert_resolved "APP_HOST uses explicit value over DOMAIN" "APP_HOST: custom.example.com"
    teardown
}

test_secret_key_base_resolved() {
    setup; generate "kamal-proxy" "SECRET_KEY_BASE=super-secret-key"
    assert_resolved "SECRET_KEY_BASE passed through" "SECRET_KEY_BASE: super-secret-key"
    teardown
}

test_rails_max_threads_resolved() {
    setup; generate "kamal-proxy" "RAILS_MAX_THREADS=12"
    assert_resolved "RAILS_MAX_THREADS=12 resolved" "RAILS_MAX_THREADS: \"12\""
    teardown
}

test_rails_max_threads_default_3() {
    setup; generate "kamal-proxy"
    assert_resolved "RAILS_MAX_THREADS defaults to 3" "RAILS_MAX_THREADS: \"3\""
    teardown
}

test_port_resolved() {
    setup; generate "ip-only" "APP_PORT=8080"
    assert_resolved "port resolves to 8080" "published: \"8080\""
    teardown
}

test_port_default_80() {
    setup; generate "ip-only"
    assert_resolved "port defaults to 80" "published: \"80\""
    teardown
}

test_kamal_proxy_no_traefik_labels_resolved() {
    setup; generate "kamal-proxy"
    assert_resolved_not "kamal-proxy: no traefik labels" "traefik"
    teardown
}

test_standalone_traefik_labels_resolved() {
    setup; generate "standalone" "DOMAIN=ssl.example.com" "LETSENCRYPT_EMAIL=admin@example.com" "CF_DNS_API_TOKEN=dns-token"
    assert_resolved "standalone: traefik.enable resolved" "traefik.enable: \"true\""
    assert_resolved "standalone: traefik rule resolved" "Host(\`ssl.example.com\`)"
    teardown
}

test_existing_traefik_labels_resolved() {
    setup; generate "existing-traefik" "DOMAIN=app.example.com"
    assert_resolved "existing-traefik: traefik labels resolved" "Host(\`app.example.com\`)"
    teardown
}

test_cloudflare_env_resolved() {
    setup; generate "cloudflare" "DOMAIN=tunnel.example.com" "CF_TUNNEL_TOKEN=tok-secret"
    assert_resolved "cloudflare: TUNNEL_TOKEN resolved" "TUNNEL_TOKEN: tok-secret"
    teardown
}

# ── Main ─────────────────────────────────────

main() {
    # Skip if docker not available
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Docker not found — skipping integration tests${NC}"
        exit 0
    fi
    if ! docker compose version &>/dev/null 2>&1; then
        echo -e "${RED}Docker Compose not found — skipping integration tests${NC}"
        exit 0
    fi

    echo -e "${BOLD}Installer Integration Test Suite${NC}"
    echo "  (uses 'docker compose config' to resolve .env variables)"
    echo ""

    echo -e "${BOLD}Variable resolution:${NC}"
    test_image_tag_resolved_from_env
    test_image_tag_default_latest
    test_app_host_resolved_from_domain
    test_app_host_explicit_value
    test_secret_key_base_resolved
    test_rails_max_threads_resolved
    test_rails_max_threads_default_3
    test_port_resolved
    test_port_default_80

    echo ""
    echo -e "${BOLD}Mode-specific resolved output:${NC}"
    test_kamal_proxy_no_traefik_labels_resolved
    test_standalone_traefik_labels_resolved
    test_existing_traefik_labels_resolved
    test_cloudflare_env_resolved

    echo ""
    summary
}

main "$@"
