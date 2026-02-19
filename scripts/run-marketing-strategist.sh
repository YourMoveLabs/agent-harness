#!/bin/bash
# Marketing Strategist: content performance analysis, SEO gaps, growth directives
# Runs weekly to direct the Content Creator's topic selection.
#
# Usage: ./scripts/run-marketing-strategist.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_ROOT="${HARNESS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"

log() { echo "[marketing-strategist $(date -u +%H:%M:%S)] $*"; }

log "=== Marketing Strategist ==="
echo ""

# Ensure content strategy exists — the strategist needs it as a baseline
if [ ! -f config/content-strategy.md ]; then
    log "WARNING: config/content-strategy.md not found — Marketing Strategist will have limited context"
fi

log "Running Marketing Strategist agent — content performance and growth directives"
if "$HARNESS_ROOT/agents/run-agent.sh" marketing-strategist; then
    log "  Marketing Strategist agent completed successfully"
else
    log "  Marketing Strategist agent exited with error"
fi

echo ""
log "=== Marketing Strategist complete ==="
