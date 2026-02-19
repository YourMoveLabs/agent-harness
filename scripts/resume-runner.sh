#!/bin/bash
# Resume the runner after maintenance — re-enable all agent workflows.
# Usage: ./scripts/resume-runner.sh [REPO]
set -euo pipefail

REPO="${1:-YourMoveLabs/agent-fishbowl}"

echo "Resuming workflows for $REPO..."

for wf in agent-engineer.yml agent-infra-engineer.yml agent-reviewer.yml agent-product-owner.yml agent-scans.yml agent-user-experience.yml agent-strategic.yml agent-triage.yml agent-site-reliability.yml agent-content-creator.yml agent-product-analyst.yml agent-qa-analyst.yml agent-financial-analyst.yml agent-customer-ops.yml agent-marketing-strategist.yml agent-escalation-lead.yml agent-human-ops.yml; do
  gh workflow enable "$wf" --repo "$REPO" 2>/dev/null && echo "  Enabled $wf" || true
done

echo "All workflows re-enabled. The team is back online."
