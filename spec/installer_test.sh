#!/usr/bin/env bash
# Test suite for deploy/installer.sh compose generation.
# Tests variable resolution and mode-specific output.

set -eo pipefail

TESTS_RAN=0
TESTS_PASSED=0
TEST_DIR=""
COMPOSE_PATH=""

# ── Colors ───────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { true; }
info() { true; }

# ── Import compose generation functions ──────
COMPOSE_OUT=""
DEPLOY_DIR=""
NGINX_CONF=""
PROJECT_DIR=""

eval "$(sed -n '/^write_env_file/,/^main()/p' deploy/installer.sh | head -n -2)"

# ── Helpers ──────────────────────────────────

setup()    { TEST_DIR=$(mktemp -d); }
teardown() { rm -rf "$TEST_DIR"; }
cleanup()  { unset TAG DOMAIN APP_HOST SECRET_KEY_BASE TRAEFIK_NETWORK ENTRYPOINT DEPLOY_MODE MODE APP_PORT SERVICE_URL DEPLOY_DIR NGINX_CONF COMPOSE_OUT PG_COMPOSE_OUT DB_PROVIDER DB_USERNAME DB_PASSWORD POSTGRES_USER POSTGRES_PASSWORD; }

pass() { echo -e "  ${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); TESTS_RAN=$((TESTS_RAN + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; TESTS_RAN=$((TESTS_RAN + 1)); }

assert_contains() {
    local file="$1" pattern="$2" label="$3"
    if [ ! -f "$file" ]; then fail "$label — file not found: $file"; return; fi
    if grep -q "$pattern" "$file"; then pass "$label"
    else
        fail "$label — expected '$pattern' not found"
        head -5 "$file" | sed 's/^/    /'
    fi
}

assert_not_contains() {
    local file="$1" pattern="$2" label="$3"
    if [ ! -f "$file" ]; then fail "$label — file not found: $file"; return; fi
    if grep -q "$pattern" "$file"; then
        fail "$label — unexpected '$pattern' found"
        grep "$pattern" "$file" | head -3 | sed 's/^/    /'
    else
        pass "$label"
    fi
}

# Generate compose for a mode with given env overrides
# Usage: generate <mode> [VAR=value ...]
generate() {
    local mode="$1"; shift
    COMPOSE_PATH="${TEST_DIR}/compose_${mode}.yml"

    # Defaults
    export TAG="${TAG:-latest}"
    export DOMAIN="${DOMAIN:-test.example.com}"
    export APP_HOST="${APP_HOST:-$DOMAIN}"
    export TRAEFIK_NETWORK="${TRAEFIK_NETWORK:-kamal}"
    export ENTRYPOINT="${ENTRYPOINT:-websecure}"
    export APP_PORT="${APP_PORT:-80}"
    export SERVICE_URL="${SERVICE_URL:-http://up-timer:80}"
    export DEPLOY_MODE="$mode"
    export COMPOSE_OUT="$COMPOSE_PATH"
    export PG_COMPOSE_OUT="${TEST_DIR}/docker-compose.pg.yml"
    export DEPLOY_DIR="$TEST_DIR"
    export NGINX_CONF="$TEST_DIR/nginx.conf"

    # Apply overrides
    local var val
    for pair in "$@"; do
        var="${pair%%=*}"
        val="${pair#*=}"
        export "$var"="$val"
    done

    MODE="$mode"
    generate_compose 2>/dev/null || true
    cleanup
}

summary() {
    echo ""
    echo -e "${BOLD}Results:${NC} $TESTS_PASSED/$TESTS_RAN passed"
    [ "$TESTS_PASSED" -eq "$TESTS_RAN" ]
}

# ── Tests ────────────────────────────────────

test_image_tag_is_template() {
    setup; generate "kamal-proxy" "TAG=v2.0.0"
    assert_contains "$COMPOSE_PATH" 'binilsn/up-timer:${TAG:-latest}' \
        "kamal-proxy: image uses template variable"
    teardown
}

test_kamal_proxy_no_traefik_labels() {
    setup; generate "kamal-proxy"
    assert_not_contains "$COMPOSE_PATH" "traefik" \
        "kamal-proxy: no Traefik labels"
    teardown
}

test_kamal_proxy_external_network() {
    setup; generate "kamal-proxy"
    assert_contains "$COMPOSE_PATH" "external: true" \
        "kamal-proxy: uses external network"
    assert_contains "$COMPOSE_PATH" 'name: ${TRAEFIK_NETWORK}' \
        "kamal-proxy: network name from env var"
    teardown
}

test_kamal_proxy_no_ports() {
    setup; generate "kamal-proxy"
    assert_not_contains "$COMPOSE_PATH" "ports:" \
        "kamal-proxy: no ports exposed"
    teardown
}

test_standalone_traefik_has_labels() {
    setup; generate "standalone"
    assert_contains "$COMPOSE_PATH" "traefik.enable=true" \
        "standalone: has Traefik labels"
    assert_contains "$COMPOSE_PATH" "traefik:" \
        "standalone: includes Traefik service"
    teardown
}

test_standalone_traefik_ports_exposed() {
    setup; generate "standalone"
    assert_contains "$COMPOSE_PATH" '"80:80"' \
        "standalone: port 80 exposed"
    assert_contains "$COMPOSE_PATH" '"443:443"' \
        "standalone: port 443 exposed"
    teardown
}

test_existing_traefik_has_labels() {
    setup; generate "existing-traefik" "TRAEFIK_NETWORK=traefik-public"
    assert_contains "$COMPOSE_PATH" "traefik.enable=true" \
        "existing-traefik: has Traefik labels"
    assert_contains "$COMPOSE_PATH" "external: true" \
        "existing-traefik: uses external network"
    teardown
}

test_ip_only_exposes_port() {
    setup; generate "ip-only" "APP_PORT=8080"
    assert_contains "$COMPOSE_PATH" "ports:" \
        "ip-only: has ports section"
    assert_contains "$COMPOSE_PATH" '${APP_PORT:-80}:80' \
        "ip-only: uses APP_PORT variable with default 80"
    teardown
}

test_cloudflare_includes_tunnel() {
    setup; generate "cloudflare" "DOMAIN=tunnel.example.com"
    assert_contains "$COMPOSE_PATH" "cloudflared:" \
        "cloudflare: includes cloudflared service"
    assert_contains "$COMPOSE_PATH" "tunnel --config /etc/cloudflared/config.yml run" \
        "cloudflare: uses config file"
    assert_contains "$COMPOSE_PATH" "cloudflared.yml:/etc/cloudflared/config.yml:ro" \
        "cloudflare: mounts config file"
    # Check config file was generated
    if [ -f "$TEST_DIR/cloudflared.yml" ]; then
        assert_contains "$TEST_DIR/cloudflared.yml" "hostname: tunnel.example.com" \
            "cloudflare: config has domain"
        assert_contains "$TEST_DIR/cloudflared.yml" "service: http://up-timer:80" \
            "cloudflare: config has service URL"
    else
        fail "cloudflare: config file not generated at $TEST_DIR/cloudflared.yml"
    fi
    teardown
}

test_nginx_has_proxy_service() {
    setup; generate "nginx" "DOMAIN=uptime.example.com"
    assert_contains "$COMPOSE_PATH" "nginx:" \
        "nginx: includes nginx service"
    assert_contains "$COMPOSE_PATH" '"80:80"' \
        "nginx: port 80 exposed"
    teardown
}

test_pg_override_generated() {
    setup; generate "kamal-proxy" "DB_PROVIDER=postgres"
    local pg_file="${TEST_DIR}/docker-compose.pg.yml"
    assert_contains "$pg_file" "postgres:17-alpine" \
        "postgres: generates docker-compose.pg.yml with postgres image"
    assert_contains "$pg_file" "uptimer-db" \
        "postgres: container named uptimer-db"
    assert_contains "$pg_file" 'POSTGRES_USER' \
        "postgres: has POSTGRES_USER env var"
    assert_contains "$pg_file" 'POSTGRES_PASSWORD' \
        "postgres: has POSTGRES_PASSWORD env var"
    assert_contains "$pg_file" "up-timer-pgdata:" \
        "postgres: has pgdata volume"
    assert_contains "$pg_file" "DATABASE_URL" \
        "postgres: sets DATABASE_URL"
    teardown
}

test_pg_override_not_generated_for_sqlite() {
    setup; generate "kamal-proxy" "DB_PROVIDER=sqlite"
    local pg_file="${TEST_DIR}/docker-compose.pg.yml"
    if [ -f "$pg_file" ]; then
        fail "postgres: override file should not exist for sqlite"
    else
        pass "postgres: no override file generated for sqlite"
    fi
    teardown
}

test_pg_override_all_modes() {
    for mode in standalone kamal-proxy existing-traefik nginx cloudflare ip-only; do
        setup
        if [ "$mode" = "cloudflare" ]; then
            generate "$mode" "DB_PROVIDER=postgres" "DOMAIN=test.example.com"
        else
            generate "$mode" "DB_PROVIDER=postgres"
        fi
        local pg_file="${TEST_DIR}/docker-compose.pg.yml"
        assert_contains "$pg_file" "postgres:17-alpine" \
            "$mode: generates PG override with postgres image"
        teardown
    done
}

test_all_modes_include_up_timer() {
    for mode in standalone kamal-proxy existing-traefik nginx cloudflare ip-only; do
        setup
        if [ "$mode" = "cloudflare" ]; then
            generate "$mode" "DOMAIN=test.example.com"
        else
            generate "$mode"
        fi
        assert_contains "$COMPOSE_PATH" "up-timer:" \
            "$mode: includes up-timer service"
        teardown
    done
}

test_all_modes_have_healthcheck() {
    for mode in standalone kamal-proxy existing-traefik nginx cloudflare ip-only; do
        setup; generate "$mode"
        assert_contains "$COMPOSE_PATH" "healthcheck:" "$mode: has healthcheck"
        teardown
    done
}

test_all_modes_have_rails_max_threads() {
    for mode in standalone kamal-proxy existing-traefik nginx cloudflare ip-only; do
        setup; generate "$mode"
        assert_contains "$COMPOSE_PATH" 'RAILS_MAX_THREADS' "$mode: has RAILS_MAX_THREADS env"
        assert_contains "$COMPOSE_PATH" 'RAILS_MAX_THREADS:-3}' "$mode: RAILS_MAX_THREADS defaults to 3"
        teardown
    done
}

test_write_env_file_mailgun() {
    setup
    export ENV_FILE="${TEST_DIR}/.env"

    # Test: custom API host written as literal value
    export MAILGUN_API_HOST="api.eu.mailgun.net"
    export MAILGUN_API_KEY="key-abc123"
    export MAILGUN_DOMAIN="mg.example.com"
    export MAIL_PROVIDER="mailgun"
    export MAIL_FROM="noreply@example.com"
    export TAG="latest"
    write_env_file

    assert_contains "$ENV_FILE" 'MAILGUN_API_HOST=api.eu.mailgun.net' \
        "env: MAILGUN_API_HOST is literal value"
    assert_not_contains "$ENV_FILE" '\${MAILGUN_API_HOST:-api.mailgun.net}' \
        "env: MAILGUN_API_HOST is not a template"
    assert_not_contains "$ENV_FILE" '\${MAILGUN_API_HOST:-}' \
        "env: MAILGUN_API_HOST is not an empty template"
    teardown

    # Test: empty API host omitted from env file
    setup
    export ENV_FILE="${TEST_DIR}/.env"
    export MAILGUN_API_HOST=""
    export MAILGUN_API_KEY="key-abc123"
    export MAILGUN_DOMAIN="mg.example.com"
    export MAIL_PROVIDER="mailgun"
    export MAIL_FROM="noreply@example.com"
    export TAG="latest"
    write_env_file

    assert_contains "$ENV_FILE" 'MAILGUN_API_HOST=' \
        "env: MAILGUN_API_HOST present when empty"
    teardown
}

test_all_modes_have_volumes() {
    for mode in standalone kamal-proxy existing-traefik nginx cloudflare ip-only; do
        setup; generate "$mode"
        assert_contains "$COMPOSE_PATH" "up-timer-storage:" "$mode: has storage volume"
        assert_contains "$COMPOSE_PATH" "up-timer-db:"     "$mode: has db volume"
        teardown
    done
}

# ── Main ─────────────────────────────────────

main() {
    echo -e "${BOLD}Installer Test Suite${NC}" && echo ""

    echo -e "${BOLD}Kamal Proxy mode:${NC}"
    test_image_tag_is_template
    test_kamal_proxy_no_traefik_labels
    test_kamal_proxy_external_network
    test_kamal_proxy_no_ports

    echo "" && echo -e "${BOLD}Standalone Traefik mode:${NC}"
    test_standalone_traefik_has_labels
    test_standalone_traefik_ports_exposed

    echo "" && echo -e "${BOLD}Existing Traefik mode:${NC}"
    test_existing_traefik_has_labels

    echo "" && echo -e "${BOLD}Other modes:${NC}"
    test_ip_only_exposes_port
    test_cloudflare_includes_tunnel
    test_nginx_has_proxy_service

    echo "" && echo -e "${BOLD}PostgreSQL mode:${NC}"
    test_pg_override_generated
    test_pg_override_not_generated_for_sqlite
    test_pg_override_all_modes

    echo "" && echo -e "${BOLD}Mailgun env file:${NC}"
    test_write_env_file_mailgun

    echo "" && echo -e "${BOLD}Cross-mode consistency:${NC}"
    test_all_modes_include_up_timer
    test_all_modes_have_healthcheck
    test_all_modes_have_volumes
    test_all_modes_have_rails_max_threads

    echo ""; summary
}

main "$@"
