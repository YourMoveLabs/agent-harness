#!/bin/bash
# Codex CLI provider adapter
#
# Expected variables (set by run-agent.sh before sourcing):
#   PROMPT_TEXT      - Assembled prompt (identity + job + partials)
#   ALLOWED_TOOLS    - Tool allowlist string (e.g., "Bash(gh:*),Read,Write")
#   MODEL            - Model name (e.g., gpt-5.2-codex) or empty for config default
#   THINKING_BUDGET  - Not supported by Codex (ignored with warning)
#   EFFORT_LEVEL     - Reasoning effort (low/medium/high, empty=config default)
#   MAX_BUDGET       - Not supported by Codex (ignored with warning)
#   RAW_OUTPUT       - Path to write JSON output
#   LOG_FILE         - Path prefix for log files (.stderr appended)
#
# Output contract (all adapters must follow this):
#   PROVIDER_EXIT_CODE  - Must be set to the CLI tool's exit code (0=success)
#   RAW_OUTPUT file     - Must contain JSON with these fields:
#     .result           - Text output (string)
#     .total_cost_usd   - Cost in USD (number or null)  [always null for Codex]
#     .duration_ms      - Total wall time in ms (number or null)
#     .duration_api_ms  - API-only time in ms (number or null) [always null for Codex]
#     .num_turns        - Agent turn count (number or null)
#     .session_id       - Session identifier (string or null)
#     .usage            - Token usage breakdown (object or null)
#     .modelUsage       - Per-model usage breakdown (object or null) [always null for Codex]
#
# Codex-specific notes:
#   - Reads ~/.codex/config.toml for Azure auth (model_provider, base_url, env_key)
#   - Outputs JSONL events, normalized to single JSON by codex-normalize.py
#   - Tool control via --sandbox modes (coarser than Claude's per-command allowlists)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Build CLI flags ---
PROVIDER_FLAGS=()
[ -n "$MODEL" ] && PROVIDER_FLAGS+=(--model "$MODEL")
[ -n "$EFFORT_LEVEL" ] && PROVIDER_FLAGS+=(--config "model_reasoning_effort=$EFFORT_LEVEL")

# Unsupported features — warn and skip
if [ -n "$MAX_BUDGET" ]; then
    echo "WARNING: Codex does not support --max-budget-usd (ignoring \$$MAX_BUDGET cap)"
fi
if [ -n "$THINKING_BUDGET" ] && [ "$THINKING_BUDGET" != "0" ]; then
    echo "WARNING: Codex does not support thinking_budget (ignoring $THINKING_BUDGET)"
fi

# --- Sandbox mode from ALLOWED_TOOLS ---
# Map Claude's granular tool allowlist to Codex's 3 sandbox modes:
#   Write|Edit in tools          → workspace-write (can modify files in project)
#   Bash(ruff|npx|pip|chmod|...) → danger-full-access (needs unrestricted shell)
#   Read|Glob|Grep only          → read-only (default, safest)
SANDBOX="read-only"
if echo "$ALLOWED_TOOLS" | grep -qE '(Write|Edit)'; then
    SANDBOX="workspace-write"
fi
if echo "$ALLOWED_TOOLS" | grep -qE 'Bash\((ruff|npx|pip|chmod|python3)'; then
    SANDBOX="danger-full-access"
fi

# --- Invoke ---
# Feed prompt via here-string (<<<) so codex is PIPESTATUS[0] in the pipeline.
# JSONL output is normalized to single JSON by codex-normalize.py.
codex exec \
    --json \
    --sandbox "$SANDBOX" \
    --full-auto \
    --ephemeral \
    "${PROVIDER_FLAGS[@]}" \
    - \
    2>"$LOG_FILE.stderr" \
    <<< "$PROMPT_TEXT" | \
    python3 "$SCRIPT_DIR/codex-normalize.py" | tee "$RAW_OUTPUT"

PROVIDER_EXIT_CODE=${PIPESTATUS[0]}
