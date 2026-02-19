#!/bin/bash
# Financial Analyst: revenue tracking, cost analysis, P&L reporting
# Runs daily to track financial health and feed signals to the PM.
#
# Usage: ./scripts/run-financial-analyst.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_ROOT="${HARNESS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"

log() { echo "[financial-analyst $(date -u +%H:%M:%S)] $*"; }

log "=== Financial Analyst ==="
echo ""

# Ensure goals.md exists — the agent needs it for strategic context
if [ ! -f config/goals.md ]; then
    log "ERROR: config/goals.md not found — Financial Analyst cannot run without strategic goals"
    exit 1
fi

log "Running Financial Analyst agent — revenue tracking and cost analysis"
if "$HARNESS_ROOT/agents/run-agent.sh" financial-analyst; then
    log "  Financial Analyst agent completed successfully"
else
    log "  Financial Analyst agent exited with error"
fi

echo ""
log "=== Financial Analyst complete ==="
