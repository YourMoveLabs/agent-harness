#!/bin/bash
# Check credential consistency across dev server and runner VM.
# Verifies: PEM files, .env entries, KEY_PATH consistency, Codex CLI setup.
#
# Usage: ./scripts/check-credentials.sh [runner-host]
# Default runner: 20.127.56.119
set -euo pipefail

RUNNER_HOST="${1:-20.127.56.119}"
PEM_DIR="$HOME/.config/agent-harness"
FISHBOWL_ENV="${PROJECT_ROOT:-$(pwd)}/.env"
RUNNER_ENV="\$HOME/.config/agent-harness/.env"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ERRORS=0

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; ERRORS=$((ERRORS + 1)); }

echo "=== Credential Consistency Check ==="
echo "Dev server: $(hostname)"
echo "Runner VM:  $RUNNER_HOST"
echo ""

# --- 1. Dev server: PEM files ---
echo "--- Dev Server: PEM files ($PEM_DIR) ---"
DEV_PEMS=$(ls "$PEM_DIR"/*.pem 2>/dev/null | xargs -I {} basename {} .pem | sort)
DEV_PEM_COUNT=$(echo "$DEV_PEMS" | wc -l)
echo "  Found: $DEV_PEM_COUNT PEM files"

# --- 2. Dev server: .env entries ---
echo "--- Dev Server: .env ($FISHBOWL_ENV) ---"
if [ -f "$FISHBOWL_ENV" ]; then
    DEV_ENV_ROLES=$(grep KEY_PATH "$FISHBOWL_ENV" | sed 's/.*\///' | sed 's/\.pem//' | sort)
    DEV_ENV_COUNT=$(echo "$DEV_ENV_ROLES" | wc -l)
    echo "  Found: $DEV_ENV_COUNT KEY_PATH entries"

    # Check path consistency
    BAD_PATHS=$(grep KEY_PATH "$FISHBOWL_ENV" | grep -v "agent-harness" || true)
    if [ -n "$BAD_PATHS" ]; then
        fail "KEY_PATH entries not pointing to agent-harness:"
        echo "$BAD_PATHS" | while read -r line; do echo "    $line"; done
    else
        ok "All KEY_PATH entries point to ~/.config/agent-harness/"
    fi

    # Check PEM files match .env roles
    MISSING_PEMS=$(comm -23 <(echo "$DEV_ENV_ROLES") <(echo "$DEV_PEMS"))
    if [ -n "$MISSING_PEMS" ]; then
        fail "Roles in .env but missing PEM files: $MISSING_PEMS"
    else
        ok "All .env roles have matching PEM files"
    fi

    ORPHAN_PEMS=$(comm -13 <(echo "$DEV_ENV_ROLES") <(echo "$DEV_PEMS"))
    if [ -n "$ORPHAN_PEMS" ]; then
        warn "PEM files without .env entries: $ORPHAN_PEMS"
    fi
else
    fail ".env not found at $FISHBOWL_ENV"
fi

echo ""

# --- 3. Runner VM: PEM files ---
echo "--- Runner VM ($RUNNER_HOST): PEM files ---"
RUNNER_PEMS=$(ssh "$RUNNER_HOST" "ls \$HOME/.config/agent-harness/*.pem 2>/dev/null | xargs -I {} basename {} .pem | sort" 2>/dev/null || echo "SSH_FAILED")
if [ "$RUNNER_PEMS" = "SSH_FAILED" ]; then
    fail "Cannot SSH to $RUNNER_HOST"
else
    RUNNER_PEM_COUNT=$(echo "$RUNNER_PEMS" | wc -l)
    echo "  Found: $RUNNER_PEM_COUNT PEM files"

    # Compare dev vs runner PEMs
    MISSING_ON_RUNNER=$(comm -23 <(echo "$DEV_PEMS") <(echo "$RUNNER_PEMS"))
    if [ -n "$MISSING_ON_RUNNER" ]; then
        fail "PEMs on dev but missing from runner: $MISSING_ON_RUNNER"
    else
        ok "Runner has all PEM files from dev ($RUNNER_PEM_COUNT/$DEV_PEM_COUNT)"
    fi
fi

# --- 4. Runner VM: .env entries ---
echo "--- Runner VM ($RUNNER_HOST): .env ---"
RUNNER_ENV_ROLES=$(ssh "$RUNNER_HOST" "grep KEY_PATH \$HOME/.config/agent-harness/.env 2>/dev/null | sed 's/.*\///' | sed 's/\.pem//' | sort" 2>/dev/null || echo "SSH_FAILED")
if [ "$RUNNER_ENV_ROLES" = "SSH_FAILED" ]; then
    fail "Cannot read runner .env"
else
    RUNNER_ENV_COUNT=$(echo "$RUNNER_ENV_ROLES" | wc -l)
    echo "  Found: $RUNNER_ENV_COUNT KEY_PATH entries"

    # Check path consistency on runner
    RUNNER_BAD_PATHS=$(ssh "$RUNNER_HOST" "grep KEY_PATH \$HOME/.config/agent-harness/.env | grep -v agent-harness" 2>/dev/null || true)
    if [ -n "$RUNNER_BAD_PATHS" ]; then
        fail "Runner KEY_PATH entries not pointing to agent-harness:"
        echo "$RUNNER_BAD_PATHS" | while read -r line; do echo "    $line"; done
    else
        ok "All runner KEY_PATH entries point to ~/.config/agent-harness/"
    fi

    # Compare dev vs runner .env roles
    MISSING_ENV_ON_RUNNER=$(comm -23 <(echo "$DEV_ENV_ROLES") <(echo "$RUNNER_ENV_ROLES"))
    if [ -n "$MISSING_ENV_ON_RUNNER" ]; then
        fail "Roles in dev .env but missing from runner: $MISSING_ENV_ON_RUNNER"
    else
        ok "Runner has all .env entries from dev ($RUNNER_ENV_COUNT/$DEV_ENV_COUNT)"
    fi
fi

echo ""

# --- 5. Codex CLI ---
echo "--- Codex CLI ---"
DEV_CODEX=$(codex --version 2>/dev/null || echo "NOT_INSTALLED")
RUNNER_CODEX=$(ssh "$RUNNER_HOST" "codex --version 2>/dev/null || echo NOT_INSTALLED" 2>/dev/null || echo "SSH_FAILED")

if [ "$DEV_CODEX" = "NOT_INSTALLED" ]; then
    warn "Codex CLI not installed on dev server"
else
    ok "Dev server: $DEV_CODEX"
fi

if [ "$RUNNER_CODEX" = "NOT_INSTALLED" ]; then
    warn "Codex CLI not installed on runner"
elif [ "$RUNNER_CODEX" = "SSH_FAILED" ]; then
    fail "Cannot check runner Codex version"
else
    ok "Runner VM: $RUNNER_CODEX"
fi

if [ "$DEV_CODEX" != "$RUNNER_CODEX" ] && [ "$DEV_CODEX" != "NOT_INSTALLED" ] && [ "$RUNNER_CODEX" != "NOT_INSTALLED" ]; then
    warn "Codex versions differ: dev=$DEV_CODEX runner=$RUNNER_CODEX"
fi

# --- 6. Codex config ---
DEV_CODEX_KEY=$(grep AZURE_CODEX "$FISHBOWL_ENV" 2>/dev/null | wc -l || echo 0)
RUNNER_CODEX_KEY=$(ssh "$RUNNER_HOST" "grep AZURE_CODEX \$HOME/.config/agent-harness/.env 2>/dev/null | wc -l" 2>/dev/null || echo 0)

if [ "$DEV_CODEX_KEY" -gt 0 ]; then
    ok "Dev server: AZURE_CODEX_API_KEY present in .env"
else
    warn "Dev server: AZURE_CODEX_API_KEY missing from .env"
fi

if [ "$RUNNER_CODEX_KEY" -gt 0 ]; then
    ok "Runner VM: AZURE_CODEX_API_KEY present in .env"
else
    warn "Runner VM: AZURE_CODEX_API_KEY missing from .env"
fi

echo ""
echo "=== Summary ==="
if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}All checks passed.${NC}"
else
    echo -e "${RED}$ERRORS error(s) found.${NC}"
fi
exit "$ERRORS"
