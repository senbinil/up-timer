#!/usr/bin/env bash
# Shell-level specs for bin/zjit-env.sh — the ZJIT_ENABLE opt-in toggle.
#
# The real `ruby` is replaced by a stub on PATH so the "ZJIT-capable build" and
# "built without ZJIT" branches are both exercised deterministically, regardless
# of the interpreter running the test.
#
# Usage: bash spec/zjit_env_test.sh

set -eo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="${PROJECT_DIR}/bin/zjit-env.sh"

TESTS_RAN=0
TESTS_PASSED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}✓${NC} $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); TESTS_RAN=$((TESTS_RAN + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; TESTS_RAN=$((TESTS_RAN + 1)); }

TMP_ROOT="$(mktemp -d)"
SHIM_DIR=""
STDERR_FILE="${TMP_ROOT}/stderr"

cleanup() {
    rm -rf "$TMP_ROOT"
    if [ -n "$SHIM_DIR" ]; then rm -rf "$SHIM_DIR"; fi
}
trap cleanup EXIT

# Create a fake `ruby` earlier on PATH whose capability probe exits with $1.
# 0 == ZJIT-capable build, 1 == build without --enable-zjit.
stub_ruby() {
    if [ -n "$SHIM_DIR" ]; then rm -rf "$SHIM_DIR"; fi
    SHIM_DIR="$(mktemp -d)"
    printf '#!/usr/bin/env bash\nexit %s\n' "$1" > "$SHIM_DIR/ruby"
    chmod +x "$SHIM_DIR/ruby"
    export PATH="$SHIM_DIR:$PATH"
}

# Source the helper in a subshell and echo the resulting RUBYOPT.
# $1 = ZJIT_ENABLE value ("<unset>" to leave it unset), $2 = initial RUBYOPT
apply_helper() {
    local value="$1" initial="${2-}"
    (
        if [ "$value" = "<unset>" ]; then
            unset ZJIT_ENABLE
        else
            export ZJIT_ENABLE="$value"
        fi
        export RUBYOPT="$initial"
        # shellcheck disable=SC1090
        . "$HELPER"
        printf '%s' "${RUBYOPT:-}"
    ) 2>"$STDERR_FILE"
}

assert_eq() {
    local expected="$1" actual="$2" label="$3"
    if [ "$expected" = "$actual" ]; then
        pass "$label"
    else
        fail "$label — expected [$expected], got [$actual]"
    fi
}

assert_contains() {
    local haystack="$1" needle="$2" label="$3"
    if printf '%s' "$haystack" | grep -q -- "$needle"; then
        pass "$label"
    else
        fail "$label — [$needle] not found in [$haystack]"
    fi
}

echo "bin/zjit-env.sh (ZJIT-capable ruby)"

stub_ruby 0

assert_eq "" "$(apply_helper "<unset>")" "no-op when ZJIT_ENABLE is unset"
assert_eq "" "$(apply_helper false)" "no-op when ZJIT_ENABLE=false"
assert_eq "--zjit" "$(apply_helper true)" "enables ZJIT when ZJIT_ENABLE=true"
assert_eq "--zjit" "$(apply_helper TRUE)" "accepts case-insensitive true"
assert_eq "--zjit" "$(apply_helper 1)" "accepts 1 as truthy"
assert_eq "--zjit -W0" "$(apply_helper true "-W0")" "prepends --zjit ahead of existing RUBYOPT"
assert_eq "--zjit" "$(apply_helper true "--zjit")" "does not duplicate an existing --zjit"

echo "bin/zjit-env.sh (ruby without ZJIT support)"

stub_ruby 1

assert_eq "" "$(apply_helper true)" "leaves RUBYOPT untouched when ZJIT is unsupported"
assert_contains "$(cat "$STDERR_FILE")" "no ZJIT support" "warns when ZJIT is unsupported"
assert_eq "" "$(apply_helper "<unset>")" "stays silent when disabled on an unsupported build"

echo
echo "${TESTS_PASSED}/${TESTS_RAN} passed"
[ "$TESTS_PASSED" -eq "$TESTS_RAN" ]
