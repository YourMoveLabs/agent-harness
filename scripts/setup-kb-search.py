#!/usr/bin/env python3
"""One-time setup: create Knowledge Source + Knowledge Base on Azure AI Search.

Adapted from captainai/doc-chat-apps/shared_scripts/setup.py.
Run from the runner VM (needs MANAGED_IDENTITY_CLIENT_ID, FISHBOWL_AI_SEARCH_KEY, etc.)

Usage:
    python3 scripts/setup-kb-search.py
    python3 scripts/setup-kb-search.py --check   # verify existing resources
"""
import json
import os
import sys

import requests

# --- Configuration ---
AI_SEARCH_SERVICE = os.getenv("FISHBOWL_AI_SEARCH_SERVICE", "fishbowl-ai-search")
AI_SEARCH_KEY = os.environ["FISHBOWL_AI_SEARCH_KEY"]
AI_SEARCH_URL = f"https://{AI_SEARCH_SERVICE}.search.windows.net"
AI_SEARCH_KB_API = "2025-11-01-Preview"

SUBSCRIPTION_ID = os.environ["AZURE_SUBSCRIPTION_ID"]
RESOURCE_GROUP = "rg-agent-fishbowl"
STORAGE_ACCOUNT = "agentfishbowlstorage"
CONTAINER_NAME = "org-knowledge-approved"

MANAGED_IDENTITY_CLIENT_ID = os.environ["MANAGED_IDENTITY_CLIENT_ID"]
IDENTITY_NAME = "id-agent-fishbowl"

OPENAI_RESOURCE_URI = "https://fishbowl.cognitiveservices.azure.com"
OPENAI_API_KEY = os.environ.get("FOUNDRY_API_KEY", "")
EMBEDDING_MODEL = "text-embedding-3-large"
CHAT_MODEL = "gpt-4.1"

KS_NAME = "org-knowledge-ks"
KB_NAME = "org-knowledge-kb"


def headers():
    return {"Content-Type": "application/json", "api-key": AI_SEARCH_KEY}


def create_knowledge_source():
    """Create Knowledge Source that auto-provisions AI Search infrastructure."""
    print("[Step 1/2] Creating knowledge source...")

    resp = requests.get(
        f"{AI_SEARCH_URL}/knowledgesources/{KS_NAME}?api-version={AI_SEARCH_KB_API}",
        headers=headers(),
    )
    if resp.status_code == 200:
        print(f"  Knowledge source '{KS_NAME}' already exists")
        created = resp.json().get("azureBlobParameters", {}).get("createdResources", {})
        if created:
            print(f"    index={created.get('index')}, indexer={created.get('indexer')}")
        return

    connection_string = (
        f"ResourceId=/subscriptions/{SUBSCRIPTION_ID}"
        f"/resourceGroups/{RESOURCE_GROUP}"
        f"/providers/Microsoft.Storage/storageAccounts/{STORAGE_ACCOUNT};"
    )

    identity_resource_id = (
        f"/subscriptions/{SUBSCRIPTION_ID}"
        f"/resourcegroups/{RESOURCE_GROUP}"
        f"/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{IDENTITY_NAME}"
    )

    body = {
        "name": KS_NAME,
        "kind": "azureBlob",
        "azureBlobParameters": {
            "connectionString": connection_string,
            "containerName": CONTAINER_NAME,
            "ingestionParameters": {
                "contentExtractionMode": "minimal",
                "identity": {
                    "@odata.type": "#Microsoft.Azure.Search.DataUserAssignedIdentity",
                    "userAssignedIdentity": identity_resource_id,
                },
                "embeddingModel": {
                    "kind": "azureOpenAI",
                    "azureOpenAIParameters": {
                        "resourceUri": OPENAI_RESOURCE_URI,
                        "deploymentId": EMBEDDING_MODEL,
                        "apiKey": OPENAI_API_KEY,
                        "modelName": EMBEDDING_MODEL,
                    },
                },
                "chatCompletionModel": {
                    "kind": "azureOpenAI",
                    "azureOpenAIParameters": {
                        "resourceUri": OPENAI_RESOURCE_URI,
                        "deploymentId": CHAT_MODEL,
                        "apiKey": OPENAI_API_KEY,
                        "modelName": CHAT_MODEL,
                    },
                },
            },
        },
    }

    resp = requests.put(
        f"{AI_SEARCH_URL}/knowledgesources/{KS_NAME}?api-version={AI_SEARCH_KB_API}",
        headers=headers(),
        json=body,
    )

    if resp.status_code in (200, 201, 202):
        print(f"  Knowledge source '{KS_NAME}' created")
        result = resp.json()
        created = result.get("azureBlobParameters", {}).get("createdResources", {})
        if created:
            print(f"    datasource={created.get('datasource')}")
            print(f"    index={created.get('index')}")
            print(f"    skillset={created.get('skillset')}")
            print(f"    indexer={created.get('indexer')}")
    else:
        print(f"  FAILED: {resp.status_code} - {resp.text}", file=sys.stderr)
        sys.exit(1)


def create_knowledge_base():
    """Create Knowledge Base that references the Knowledge Source."""
    print("[Step 2/2] Creating knowledge base...")

    resp = requests.get(
        f"{AI_SEARCH_URL}/knowledgebases/{KB_NAME}?api-version={AI_SEARCH_KB_API}",
        headers=headers(),
    )
    if resp.status_code == 200:
        print(f"  Knowledge base '{KB_NAME}' already exists")
        return

    body = {
        "name": KB_NAME,
        "description": "Agent Fishbowl organizational knowledge base — durable business insights curated by the triage agent.",
        "knowledgeSources": [{"name": KS_NAME}],
        "outputMode": "extractiveData",
        "retrievalReasoningEffort": {"kind": "low"},
        "models": [
            {
                "kind": "azureOpenAI",
                "azureOpenAIParameters": {
                    "resourceUri": OPENAI_RESOURCE_URI,
                    "deploymentId": CHAT_MODEL,
                    "apiKey": OPENAI_API_KEY,
                    "modelName": CHAT_MODEL,
                },
            }
        ],
    }

    resp = requests.put(
        f"{AI_SEARCH_URL}/knowledgebases/{KB_NAME}?api-version={AI_SEARCH_KB_API}",
        headers=headers(),
        json=body,
    )

    if resp.status_code in (200, 201):
        print(f"  Knowledge base '{KB_NAME}' created")
    else:
        print(f"  FAILED: {resp.status_code} - {resp.text}", file=sys.stderr)
        sys.exit(1)


def check_resources():
    """Verify that all KB resources exist."""
    print("Checking KB resources...\n")

    # Knowledge Source
    resp = requests.get(
        f"{AI_SEARCH_URL}/knowledgesources/{KS_NAME}?api-version={AI_SEARCH_KB_API}",
        headers=headers(),
    )
    ks_ok = resp.status_code == 200
    print(f"  Knowledge Source ({KS_NAME}): {'OK' if ks_ok else 'MISSING'}")

    if ks_ok:
        created = resp.json().get("azureBlobParameters", {}).get("createdResources", {})
        for resource_type, name in created.items():
            print(f"    {resource_type}: {name}")

    # Knowledge Base
    resp = requests.get(
        f"{AI_SEARCH_URL}/knowledgebases/{KB_NAME}?api-version={AI_SEARCH_KB_API}",
        headers=headers(),
    )
    kb_ok = resp.status_code == 200
    print(f"  Knowledge Base ({KB_NAME}): {'OK' if kb_ok else 'MISSING'}")

    # Indexer status
    if ks_ok:
        indexer_name = f"{KS_NAME}-indexer"
        resp = requests.get(
            f"{AI_SEARCH_URL}/indexers/{indexer_name}/status?api-version=2024-07-01",
            headers=headers(),
        )
        if resp.status_code == 200:
            status = resp.json()
            last_result = status.get("lastResult", {})
            print(f"  Indexer ({indexer_name}): status={last_result.get('status', '?')}, "
                  f"docs={last_result.get('itemsProcessed', 0)}")
        else:
            print(f"  Indexer ({indexer_name}): CANNOT CHECK")

    return ks_ok and kb_ok


if __name__ == "__main__":
    if "--check" in sys.argv:
        ok = check_resources()
        sys.exit(0 if ok else 1)

    create_knowledge_source()
    print()
    create_knowledge_base()
    print("\nSetup complete. Upload seed documents to org-knowledge-approved, then wait for indexer.")
