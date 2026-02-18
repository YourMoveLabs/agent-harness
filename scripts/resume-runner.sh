#!/bin/bash
# Resume the runner after maintenance — re-enable all agent workflows.
# Usage: ./scripts/resume-runner.sh [REPO]
set -euo pipefail

REPO="${1:-YourMoveLabs/agent-fishbowl}"

echo "Resuming workflows for $REPO..."

for wf in agent-engineer.yml agent-reviewer.yml agent-po.yml agent-scans.yml agent-ux.yml; do
  gh workflow enable "$wf" --repo "$REPO" 2>/dev/null && echo "  Enabled $wf" || true
done

echo "All workflows re-enabled. The team is back online."
