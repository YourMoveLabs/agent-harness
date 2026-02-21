#!/bin/bash
# Claude Code provider adapter
#
# Expected variables (set by run-agent.sh before sourcing):
#   PROMPT_TEXT      - Assembled prompt (identity + job + partials)
#   ALLOWED_TOOLS    - Tool allowlist string (e.g., "Bash(gh:*),Read,Write")
#   MODEL            - Model alias (opus, sonnet) or empty for CLI default
#   THINKING_BUDGET  - MAX_THINKING_TOKENS value (0=off, N=custom, empty=default ON)
#   EFFORT_LEVEL     - Opus 4.6 adaptive thinking depth (low/medium/high, empty=default)
#   MAX_BUDGET       - USD cap per invocation (empty=no cap)
#   RAW_OUTPUT       - Path to write JSON output
#   LOG_FILE         - Path prefix for log files (.stderr appended)
#
# Output contract (all adapters must follow this):
#   PROVIDER_EXIT_CODE  - Must be set to the CLI tool's exit code (0=success)
#   RAW_OUTPUT file     - Must contain JSON with these fields:
#     .result           - Text output (string)
#     .total_cost_usd   - Cost in USD (number or null)
#     .duration_ms      - Total wall time in ms (number or null)
#     .duration_api_ms  - API-only time in ms (number or null)
#     .num_turns        - Agent turn count (number or null)
#     .session_id       - Session identifier (string or null)
#     .usage            - Token usage breakdown (object or null)
#     .modelUsage       - Per-model usage breakdown (object or null)

# --- Claude-specific environment ---
if [ -n "$THINKING_BUDGET" ]; then
    export MAX_THINKING_TOKENS="$THINKING_BUDGET"
fi
if [ -n "$EFFORT_LEVEL" ]; then
    export CLAUDE_CODE_EFFORT_LEVEL="$EFFORT_LEVEL"
fi

# --- Build CLI flags ---
PROVIDER_FLAGS=()
[ -n "$MODEL" ] && PROVIDER_FLAGS+=(--model "$MODEL")
[ -n "$MAX_BUDGET" ] && PROVIDER_FLAGS+=(--max-budget-usd "$MAX_BUDGET")
# Opus runs: fall back to Sonnet if overloaded
[ "$MODEL" = "opus" ] && PROVIDER_FLAGS+=(--fallback-model "sonnet")

# --- Invoke ---
claude -p "$PROMPT_TEXT" \
    --allowedTools "$ALLOWED_TOOLS" \
    --output-format json \
    --no-session-persistence \
    "${PROVIDER_FLAGS[@]}" \
    2>"$LOG_FILE.stderr" | tee "$RAW_OUTPUT"

PROVIDER_EXIT_CODE=${PIPESTATUS[0]}
