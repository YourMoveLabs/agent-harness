#!/bin/bash
# kb-approve.sh — Approve a knowledge candidate (move from staging to approved).
# Usage: scripts/kb-approve.sh STAGING_BLOB_NAME [APPROVED_NAME]
# If APPROVED_NAME is not given, uses the staging filename under approved/.
set -euo pipefail

STAGING_NAME="${1:?Usage: kb-approve.sh STAGING_BLOB_NAME [APPROVED_NAME]}"
APPROVED_BLOB="${2:-$(basename "$STAGING_NAME")}"

# Strip any prefix — approved container is flat
APPROVED_BLOB="$(basename "$APPROVED_BLOB")"

ACCOUNT="agentfishbowlstorage"
STAGING_CONTAINER="org-knowledge"
APPROVED_CONTAINER="org-knowledge-approved"

az login --identity --client-id "$MANAGED_IDENTITY_CLIENT_ID" --output none 2>/dev/null || {
    echo "ERROR: Azure login failed" >&2; exit 1
}

# Copy staging → approved container
SOURCE_URL="https://${ACCOUNT}.blob.core.windows.net/${STAGING_CONTAINER}/${STAGING_NAME}"
az storage blob copy start \
    --account-name "$ACCOUNT" \
    --destination-container "$APPROVED_CONTAINER" \
    --destination-blob "$APPROVED_BLOB" \
    --source-uri "$SOURCE_URL" \
    --auth-mode login 2>/dev/null

# Delete staging copy
az storage blob delete \
    --account-name "$ACCOUNT" \
    --container-name "$STAGING_CONTAINER" \
    --name "$STAGING_NAME" \
    --auth-mode login 2>/dev/null

echo "Approved: $STAGING_NAME → $APPROVED_CONTAINER/$APPROVED_BLOB"
