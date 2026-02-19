#!/bin/bash
# Shared agent runner — invokes Claude CLI with a role-specific prompt.
# Usage: ./agents/run-agent.sh <role>
# Roles: po, engineer, reviewer, tech-lead, triage, ux, pm, sre
set -euo pipefail

ROLE="${1:-}"
if [ -z "$ROLE" ]; then
    echo "Usage: $0 <role>"
    echo "Roles: po, engineer, engineer-alpha, engineer-bravo, engineer-charlie, reviewer,"
    echo "       reviewer-alpha, reviewer-bravo, tech-lead, triage, ux, pm, sre,"
    echo "       content-creator, product-analyst, qa-analyst, customer-ops,"
    echo "       financial-analyst, marketing-strategist, judge, vp-human-ops"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_ROOT="${HARNESS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"

# PROMPT_ROLE allows multi-instance agents to share a prompt.
# e.g., engineer-alpha uses PROMPT_ROLE=engineer → agents/prompts/engineer.md
PROMPT_ROLE="${PROMPT_ROLE:-$ROLE}"
PROMPT_FILE="$HARNESS_ROOT/agents/prompts/${PROMPT_ROLE}.md"
LOG_DIR="${AGENT_LOG_DIR:-/tmp/agent-logs}"
LOG_FILE="$LOG_DIR/${ROLE}-$(date +%Y%m%d-%H%M%S).log"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "ERROR: Prompt file not found: $PROMPT_FILE"
    echo "Available roles:"
    ls "$HARNESS_ROOT/agents/prompts/"*.md 2>/dev/null | xargs -I {} basename {} .md
    exit 1
fi

mkdir -p "$LOG_DIR"

# --- GitHub App Identity (per-role) ---
# Each role has its own GitHub App for distinct identity on GitHub.
# .env vars: GITHUB_APP_<ROLE>_ID, GITHUB_APP_<ROLE>_INSTALLATION_ID, etc.
ENV_FILE="$PROJECT_ROOT/.env"
if [ ! -f "$ENV_FILE" ]; then
    ENV_FILE="$HOME/.config/agent-harness/.env"
fi
if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +a
else
    echo "WARNING: No .env found at $PROJECT_ROOT/.env or $HOME/.config/agent-harness/.env"
fi

# Convert role to uppercase for env var lookup (handle hyphens → underscores)
ROLE_UPPER=$(echo "$ROLE" | tr '[:lower:]-' '[:upper:]_')
APP_ID_VAR="GITHUB_APP_${ROLE_UPPER}_ID"
APP_INSTALL_VAR="GITHUB_APP_${ROLE_UPPER}_INSTALLATION_ID"
APP_KEY_VAR="GITHUB_APP_${ROLE_UPPER}_KEY_PATH"
APP_USER_VAR="GITHUB_APP_${ROLE_UPPER}_USER_ID"
APP_BOT_VAR="GITHUB_APP_${ROLE_UPPER}_BOT_NAME"

APP_ID="${!APP_ID_VAR:-}"
APP_INSTALL="${!APP_INSTALL_VAR:-}"
APP_KEY="${!APP_KEY_VAR:-}"
APP_USER_ID="${!APP_USER_VAR:-0}"
APP_BOT_NAME="${!APP_BOT_VAR:-fishbowl-${ROLE}}"

if [ -n "$APP_ID" ] && [ -n "$APP_INSTALL" ] && [ -n "$APP_KEY" ]; then
    # shellcheck source=/dev/null
    source "$HARNESS_ROOT/scripts/github-app-token.sh"

    GH_TOKEN=$(get_github_app_token "$APP_ID" "$APP_INSTALL" "$APP_KEY")
    if [ -z "$GH_TOKEN" ] || [ "$GH_TOKEN" = "null" ]; then
        echo "ERROR: Failed to generate GitHub App token for role: $ROLE"
        exit 1
    fi
    export GH_TOKEN

    BOT_DISPLAY="${APP_BOT_NAME}[bot]"
    BOT_EMAIL="${APP_USER_ID}+${APP_BOT_NAME}[bot]@users.noreply.github.com"
    export GIT_AUTHOR_NAME="$BOT_DISPLAY"
    export GIT_AUTHOR_EMAIL="$BOT_EMAIL"
    export GIT_COMMITTER_NAME="$BOT_DISPLAY"
    export GIT_COMMITTER_EMAIL="$BOT_EMAIL"

    echo "GitHub App: $BOT_DISPLAY (role: $ROLE)"
else
    echo "WARNING: No GitHub App for role '$ROLE' — using default identity"
    echo "  Need: ${APP_ID_VAR}, ${APP_INSTALL_VAR}, ${APP_KEY_VAR} in .env"
fi

echo ""
echo "=== Agent: ${ROLE} ==="
echo "Prompt: $PROMPT_FILE"
echo "Log: $LOG_FILE"
echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

cd "$PROJECT_ROOT"

# Use project-level git hooks (pre-commit auto-formats Python)
git config core.hooksPath .githooks

# --- Per-role tool allowlists ---
# Different roles get different tool permissions to prevent scope creep.
# Non-code agents lose Write/Edit to ensure they can't modify application code.
COMMON_TOOLS="Bash(gh:*),Bash(git:*),Bash(cat:*),Read,Glob,Grep"

case "$ROLE" in
    engineer|engineer-alpha|engineer-bravo|engineer-charlie)
        # Full access — implements code changes
        ALLOWED_TOOLS="Bash(gh:*),Bash(git:*),Bash(ruff:*),Bash(npx:*),Bash(pip:*),Bash(scripts/*),Bash(cat:*),Bash(chmod:*),Read,Write,Edit,Glob,Grep"
        ;;
    tech-lead)
        # Can write conventions and lint scripts, but not application code
        ALLOWED_TOOLS="${COMMON_TOOLS},Bash(ruff:*),Bash(npx:*),Bash(pip:*),Bash(scripts/*),Write,Edit"
        ;;
    pm)
        # Strategic agent: reads goals, manages GitHub Project roadmap via gh
        # scripts/* for project-fields.sh and roadmap-status.sh (read-only GitHub data)
        # No Glob/Grep — PM understands product through outcomes, not code
        # No Write/Edit/git — PM doesn't modify codebase files
        ALLOWED_TOOLS="Bash(gh:*),Bash(cat:*),Bash(scripts/*),Read"
        ;;
    sre)
        # Operational agent: monitors health, checks Azure resources, creates issues
        # scripts/* for health-check.sh, workflow-status.sh, find-issues.sh
        # No Write/Edit — SRE doesn't modify code. It reads, monitors, and creates issues.
        ALLOWED_TOOLS="Bash(curl:*),Bash(az:*),Bash(gh:*),Bash(python3:*),Bash(cat:*),Bash(date:*),Bash(scripts/*),Read"
        ;;
    content-creator)
        # Content generation: calls blog API, manages blob storage, tracks via gh
        # Replaces 'writer' — takes direction from Marketing Strategist
        # No Write/Edit — content creator doesn't modify app code
        ALLOWED_TOOLS="Bash(curl:*),Bash(az:*),Bash(gh:*),Bash(jq:*),Bash(cat:*),Bash(date:*),Bash(sleep:*),Bash(echo:*),Bash(scripts/*),Read,Glob,Grep"
        ;;
    writer)
        # DEPRECATED: Use content-creator. Kept for backwards compatibility during transition.
        ALLOWED_TOOLS="Bash(curl:*),Bash(az:*),Bash(gh:*),Bash(jq:*),Bash(cat:*),Bash(date:*),Bash(sleep:*),Bash(echo:*),Bash(scripts/*),Read,Glob,Grep"
        ;;
    product-analyst)
        # Market research + Stripe API + blob storage + GitHub issues
        # Shapes product offering, pricing, conversion experiments
        ALLOWED_TOOLS="Bash(curl:*),Bash(az:*),Bash(gh:*),Bash(jq:*),Bash(cat:*),Bash(date:*),Bash(scripts/*),Read,Glob,Grep"
        ;;
    financial-analyst)
        # Revenue tracking + Stripe API + cost analysis + blob storage
        # Tracks revenue vs costs, P&L, churn, dunning, margin analysis
        ALLOWED_TOOLS="Bash(curl:*),Bash(az:*),Bash(gh:*),Bash(jq:*),Bash(cat:*),Bash(date:*),Bash(scripts/*),Read,Glob,Grep"
        ;;
    qa-analyst)
        # Quality verification: API checks, data accuracy, live site validation
        # No Write/Edit — QA identifies problems, doesn't fix them
        ALLOWED_TOOLS="Bash(curl:*),Bash(gh:*),Bash(jq:*),Bash(cat:*),Bash(date:*),Bash(scripts/*),Read,Glob,Grep"
        ;;
    customer-ops)
        # Customer support: email, Stripe (limited), issue routing
        # Has curl for email APIs and limited Stripe actions (refunds)
        ALLOWED_TOOLS="Bash(curl:*),Bash(gh:*),Bash(jq:*),Bash(cat:*),Bash(date:*),Bash(scripts/*),Read,Glob,Grep"
        ;;
    marketing-strategist)
        # Content strategy: analytics, SEO, performance data → directives
        # Has curl for analytics APIs, no Write/Edit
        ALLOWED_TOOLS="Bash(curl:*),Bash(gh:*),Bash(jq:*),Bash(cat:*),Bash(date:*),Bash(scripts/*),Read,Glob,Grep"
        ;;
    judge)
        # Conflict resolution: reads dispute threads, makes binding calls
        # Read-only + gh for posting resolution comments
        ALLOWED_TOOLS="${COMMON_TOOLS},Bash(scripts/*)"
        ;;
    vp-human-ops)
        # Culture and engagement: activity feed, social posting, team morale
        # Has curl for social APIs, gh for issues/activity
        ALLOWED_TOOLS="Bash(curl:*),Bash(gh:*),Bash(jq:*),Bash(cat:*),Bash(date:*),Bash(scripts/*),Read,Glob,Grep"
        ;;
    po|reviewer|reviewer-alpha|reviewer-bravo|triage|ux)
        # Read-only + GitHub CLI — no file editing
        ALLOWED_TOOLS="${COMMON_TOOLS},Bash(scripts/*)"
        ;;
    *)
        # Fallback: read-only + GitHub CLI
        ALLOWED_TOOLS="${COMMON_TOOLS}"
        ;;
esac

echo "Tools: ${ROLE} allowlist"

# Run Claude in non-interactive mode with the role prompt.
# --output-format json: returns structured JSON with result + usage metadata
# CLAUDE.md is loaded automatically by Claude Code.
RAW_OUTPUT="$LOG_DIR/raw-output.json"
USAGE_FILE="$LOG_DIR/${ROLE}-$(date +%Y%m%d-%H%M%S)-usage.json"

# --- Prompt assembly ---
# Start with the role-specific prompt, then append shared partials for eligible roles.
PROMPT_TEXT="$(cat "$PROMPT_FILE")"

# Reflection partial: eligible agents get a "reflect on durable insights" step appended.
# Agents not listed here either have curation responsibility (triage) or are too narrow/operational.
REFLECTION="$HARNESS_ROOT/agents/prompts/partials/reflection.md"
REFLECTION_ROLES="pm po engineer reviewer product-analyst financial-analyst marketing-strategist tech-lead"
if [ -f "$REFLECTION" ] && echo "$REFLECTION_ROLES" | grep -qw "$PROMPT_ROLE"; then
    PROMPT_TEXT="$PROMPT_TEXT

$(cat "$REFLECTION")"
    echo "Reflection: enabled (appended to prompt)"
fi

claude -p "$PROMPT_TEXT" \
    --allowedTools "$ALLOWED_TOOLS" \
    --output-format json \
    2>"$LOG_FILE.stderr" | tee "$RAW_OUTPUT"

EXIT_CODE=${PIPESTATUS[0]}

# Extract the text result for human-readable log (same as --print output)
if [ -f "$RAW_OUTPUT" ] && jq -e '.result' "$RAW_OUTPUT" >/dev/null 2>&1; then
    jq -r '.result // empty' "$RAW_OUTPUT" > "$LOG_FILE"

    # Extract usage metadata into a separate JSON file
    jq '{
      role: $role,
      total_cost_usd: .total_cost_usd,
      duration_ms: .duration_ms,
      duration_api_ms: .duration_api_ms,
      num_turns: .num_turns,
      session_id: .session_id,
      usage: .usage,
      model_usage: .modelUsage,
      timestamp: $ts
    }' \
      --arg role "$ROLE" \
      --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      "$RAW_OUTPUT" > "$USAGE_FILE"

    # Print summary to workflow log
    echo ""
    echo "=== Token Usage ==="
    jq -r '"Cost: $\(.total_cost_usd // "?" | tostring) | Turns: \(.num_turns // "?" | tostring) | Duration: \((.duration_ms // 0) / 1000 | floor)s"' "$RAW_OUTPUT"
    echo ""
else
    # Fallback: JSON parsing failed, save raw output as the log
    echo "WARNING: Could not parse Claude JSON output — saving raw output"
    cp "$RAW_OUTPUT" "$LOG_FILE" 2>/dev/null || true
fi

rm -f "$RAW_OUTPUT"

echo ""
echo "=== ${ROLE} agent finished (exit: $EXIT_CODE) ==="
echo "Finished: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

exit $EXIT_CODE
