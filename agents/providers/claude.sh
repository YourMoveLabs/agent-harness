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
# Output: Writes structured JSON to RAW_OUTPUT, returns exit code via PROVIDER_EXIT_CODE.

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

# --- Invoke ---
claude -p "$PROMPT_TEXT" \
    --allowedTools "$ALLOWED_TOOLS" \
    --output-format json \
    "${PROVIDER_FLAGS[@]}" \
    2>"$LOG_FILE.stderr" | tee "$RAW_OUTPUT"

PROVIDER_EXIT_CODE=${PIPESTATUS[0]}
