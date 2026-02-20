#!/bin/bash
# Shared agent runner — invokes Claude CLI with a role-specific prompt.
# Usage: ./agents/run-agent.sh <role> [--job <job-name>]
# Role configuration lives in config/roles.json.
# Identity + Job prompts live in agents/prompts/identities/ and agents/prompts/jobs/.
set -euo pipefail

ROLE="${1:-}"
JOB=""
shift 2>/dev/null || true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --job) JOB="${2:-}"; shift 2 ;;
        *) echo "ERROR: Unknown argument: $1"; exit 1 ;;
    esac
done
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_ROOT="${HARNESS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
CONFIG_FILE="$HARNESS_ROOT/config/roles.json"

if [ -z "$ROLE" ]; then
    echo "Usage: $0 <role>"
    echo "Available roles:"
    jq -r '[.roles | keys[], (.roles | to_entries[] | select(.value | type == "object" and has("instances")) | .value.instances[])] | sort | .[]' "$CONFIG_FILE"
    exit 1
fi

# --- Role resolution from config/roles.json ---
# 1. Direct match in .roles
# 2. Instance match (e.g., engineer-alpha → engineer)
# 3. Not found → error
ROLE_CONFIG=$(jq -c --arg r "$ROLE" '
    if .roles[$r] then
        { parent: $r, config: .roles[$r] }
    else
        .roles | to_entries[]
            | select(.value | type == "object" and has("instances"))
            | select(.value.instances | index($r))
            | { parent: .key, config: .value }
    end // empty
' "$CONFIG_FILE")

if [ -z "$ROLE_CONFIG" ]; then
    echo "ERROR: Unknown role '$ROLE'"
    echo "Available roles:"
    jq -r '[.roles | keys[], (.roles | to_entries[] | select(.value | type == "object" and has("instances")) | .value.instances[])] | sort | .[]' "$CONFIG_FILE"
    exit 1
fi

PARENT_ROLE=$(echo "$ROLE_CONFIG" | jq -r '.parent')

# Check for deprecated roles
DEPRECATED=$(echo "$ROLE_CONFIG" | jq -r '.config.deprecated // empty')
if [ -n "$DEPRECATED" ]; then
    echo "WARNING: Role '$ROLE' is deprecated — use '$DEPRECATED' instead"
fi

# Resolve prompt role: config.prompt_role > parent role name (for instances) > role name
PROMPT_ROLE=$(echo "$ROLE_CONFIG" | jq -r '.config.prompt_role // empty')
if [ -z "$PROMPT_ROLE" ]; then
    PROMPT_ROLE="$PARENT_ROLE"
fi

# Resolve default job from config if not specified on command line
if [ -z "$JOB" ]; then
    JOB=$(echo "$ROLE_CONFIG" | jq -r '.config.default_job // empty')
fi

# Resolve model: job-level override > role-level > CLI default
if [ -n "$JOB" ]; then
    MODEL=$(echo "$ROLE_CONFIG" | jq -r --arg j "$JOB" '.config.job_models[$j] // .config.model // empty')
else
    MODEL=$(echo "$ROLE_CONFIG" | jq -r '.config.model // empty')
fi

PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
PROMPT_FILE="$HARNESS_ROOT/agents/prompts/${PROMPT_ROLE}.md"
LOG_DIR="${AGENT_LOG_DIR:-/tmp/agent-logs}"
LOG_FILE="$LOG_DIR/${ROLE}-$(date +%Y%m%d-%H%M%S).log"

# Validate prompt file exists (only needed for legacy non-job mode)
if [ -z "$JOB" ] && [ ! -f "$PROMPT_FILE" ]; then
    echo "ERROR: Prompt file not found: $PROMPT_FILE"
    echo "Available prompts:"
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
APP_BOT_NAME="${!APP_BOT_VAR:-${ROLE}}"

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
echo "=== Agent: ${ROLE}${JOB:+ (job: $JOB)} ==="
if [ -n "$JOB" ]; then
    echo "Identity: $HARNESS_ROOT/agents/prompts/identities/${PROMPT_ROLE}.md"
    echo "Job: $HARNESS_ROOT/agents/prompts/jobs/${PROMPT_ROLE}/${JOB}.md"
else
    echo "Prompt: $PROMPT_FILE"
fi
echo "Log: $LOG_FILE"
echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

cd "$PROJECT_ROOT"

# Use project-level git hooks (pre-commit auto-formats Python)
git config core.hooksPath .githooks

# --- Tool allowlist from config ---
# Expand ${COMMON} and ${API} presets, then set ALLOWED_TOOLS.
ALLOWED_TOOLS=$(jq -r --arg r "$ROLE" '
    ._tool_presets as $presets |
    (if .roles[$r] then .roles[$r] else .roles | to_entries[] | select(.value | type == "object" and has("instances")) | select(.value.instances | index($r)) | .value end) |
    .tools |
    gsub("\\$\\{COMMON\\}"; $presets.COMMON) |
    gsub("\\$\\{API\\}"; $presets.API)
' "$CONFIG_FILE")

if [ -z "$ALLOWED_TOOLS" ]; then
    echo "ERROR: Could not resolve tools for role '$ROLE'"
    exit 1
fi

echo "Tools: ${ROLE} allowlist"
if [ -n "$MODEL" ]; then
    echo "Model: $MODEL"
else
    echo "Model: (CLI default)"
fi

# Run Claude in non-interactive mode with the role prompt.
# --output-format json: returns structured JSON with result + usage metadata
# CLAUDE.md is loaded automatically by Claude Code.
RAW_OUTPUT="$LOG_DIR/raw-output.json"
USAGE_FILE="$LOG_DIR/${ROLE}-$(date +%Y%m%d-%H%M%S)-usage.json"

# --- Prompt assembly ---
# If --job is specified: identity + job instructions + partials
# If no --job: monolithic prompt + partials
if [ -n "$JOB" ]; then
    IDENTITY_FILE="$HARNESS_ROOT/agents/prompts/identities/${PROMPT_ROLE}.md"
    JOB_FILE="$HARNESS_ROOT/agents/prompts/jobs/${PROMPT_ROLE}/${JOB}.md"

    if [ ! -f "$IDENTITY_FILE" ]; then
        echo "ERROR: Identity file not found: $IDENTITY_FILE"
        echo "Available identities:"
        ls "$HARNESS_ROOT/agents/prompts/identities/"*.md 2>/dev/null | xargs -I {} basename {} .md || echo "  (none)"
        exit 1
    fi
    if [ ! -f "$JOB_FILE" ]; then
        echo "ERROR: Job file not found: $JOB_FILE"
        echo "Available jobs for ${PROMPT_ROLE}:"
        ls "$HARNESS_ROOT/agents/prompts/jobs/${PROMPT_ROLE}/"*.md 2>/dev/null | xargs -I {} basename {} .md || echo "  (none)"
        exit 1
    fi

    PROMPT_TEXT="$(cat "$IDENTITY_FILE")

---

## Current Job: ${JOB}

$(cat "$JOB_FILE")"
    echo "Job: ${JOB}"
else
    PROMPT_TEXT="$(cat "$PROMPT_FILE")"
fi

# Append eligible partials (reflection, knowledge-base, etc.) from config.
PARTIALS=$(echo "$ROLE_CONFIG" | jq -r '.config.partials[]?' 2>/dev/null || true)
for partial in $PARTIALS; do
    PARTIAL_FILE="$HARNESS_ROOT/agents/prompts/partials/${partial}.md"
    if [ -f "$PARTIAL_FILE" ]; then
        PROMPT_TEXT="$PROMPT_TEXT

$(cat "$PARTIAL_FILE")"
        echo "Partial: ${partial} (appended to prompt)"
    else
        echo "WARNING: Partial file not found: $PARTIAL_FILE"
    fi
done

MODEL_FLAGS=()
if [ -n "$MODEL" ]; then
    MODEL_FLAGS+=(--model "$MODEL")
fi

claude -p "$PROMPT_TEXT" \
    --allowedTools "$ALLOWED_TOOLS" \
    --output-format json \
    "${MODEL_FLAGS[@]}" \
    2>"$LOG_FILE.stderr" | tee "$RAW_OUTPUT"

EXIT_CODE=${PIPESTATUS[0]}

# Extract the text result for human-readable log (same as --print output)
if [ -f "$RAW_OUTPUT" ] && jq -e '.result' "$RAW_OUTPUT" >/dev/null 2>&1; then
    jq -r '.result // empty' "$RAW_OUTPUT" > "$LOG_FILE"

    # Extract usage metadata into a separate JSON file
    jq '{
      role: $role,
      job: $job,
      model: $model,
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
      --arg job "${JOB:-}" \
      --arg model "${MODEL:-default}" \
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
