#!/bin/bash
# Strategic review: PM evaluates goals and evolves the roadmap
# Run weekly to keep the roadmap aligned with strategic goals.
#
# Usage: ./scripts/run-strategic.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_ROOT="${HARNESS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"

log() { echo "[strategic $(date -u +%H:%M:%S)] $*"; }

log "=== Strategic Review ==="
echo ""

# Ensure goals.md exists — the PM agent needs it
if [ ! -f config/goals.md ]; then
    log "ERROR: config/goals.md not found — PM agent cannot run without strategic goals"
    exit 1
fi

# Check for objectives.md (optional but recommended)
if [ ! -f config/objectives.md ]; then
    log "NOTE: config/objectives.md not found — PM will run without signal evaluation"
fi

log "Running PM agent — evaluating goals and roadmap alignment"
if "$HARNESS_ROOT/agents/run-agent.sh" product-manager; then
    log "  PM agent completed successfully"
else
    log "  PM agent exited with error"
fi

echo ""
log "=== Strategic review complete ==="
