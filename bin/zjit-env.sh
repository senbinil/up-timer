#!/usr/bin/env sh
# Opt-in ZJIT support.
#
# Source this before launching a Ruby process. When ZJIT_ENABLE is truthy
# ("true" or "1", case-insensitive) and the Ruby build was configured with
# --enable-zjit, "--zjit" is appended to RUBYOPT so child Ruby processes start
# with the experimental ZJIT compiler enabled.
#
# It is a no-op in every other case and never fails the caller: if the running
# Ruby has no ZJIT support, it warns to stderr and continues untouched.
#
# The official ruby:4.0-* images are built with --enable-zjit, so the flag is
# available there; locally-installed interpreters generally are not.

zjit_env_enabled() {
    case "$(printf '%s' "${ZJIT_ENABLE:-}" | tr '[:upper:]' '[:lower:]')" in
        true | 1) return 0 ;;
        *) return 1 ;;
    esac
}

# The RubyVM::ZJIT constant only exists when Ruby was built with --enable-zjit.
zjit_env_supported() {
    command -v ruby >/dev/null 2>&1 || return 1
    ruby -e 'exit(defined?(RubyVM::ZJIT) ? 0 : 1)' >/dev/null 2>&1
}

zjit_env_apply() {
    zjit_env_enabled || return 0

    if ! zjit_env_supported; then
        echo "zjit: ZJIT_ENABLE is set but this Ruby has no ZJIT support; continuing without JIT" >&2
        return 0
    fi

    case " ${RUBYOPT:-} " in
        *" --zjit "*) ;; # already enabled — leave RUBYOPT alone
        *) export RUBYOPT="--zjit${RUBYOPT:+ $RUBYOPT}" ;;
    esac

    return 0
}

zjit_env_apply
