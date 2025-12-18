#!/bin/bash

# Jira MCP Wrapper Script
# This script ensures the Jira MCP container is running and connects to it

CONTAINER_NAME="jira-mcp"
IMAGE="ghcr.io/sooperset/mcp-atlassian:latest"

# Validate required environment variables
if [[ -z "$JIRA_EMAIL" ]]; then
    echo "ERROR: JIRA_EMAIL environment variable not set" >&2
    echo "Please set: export JIRA_EMAIL=\"your.email@example.com\"" >&2
    exit 1
fi

if [[ -z "$JIRA_API_TOKEN" ]]; then
    echo "ERROR: JIRA_API_TOKEN environment variable not set" >&2
    echo "Get your token from: https://id.atlassian.com/manage-profile/security/api-tokens" >&2
    exit 1
fi

if [[ -z "$JIRA_URL" ]]; then
    echo "ERROR: JIRA_URL environment variable not set" >&2
    echo "Please set: export JIRA_URL=\"https://your-company.atlassian.net\"" >&2
    exit 1
fi

# Validate JIRA_URL looks like a URL
if [[ ! "$JIRA_URL" =~ ^https?:// ]]; then
    echo "ERROR: JIRA_URL must be a valid HTTP/HTTPS URL" >&2
    echo "Current value: $JIRA_URL" >&2
    exit 1
fi

# Update last_used label on existing container
if docker container inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
    docker update --label-add "last_used=$(date +%s)" "${CONTAINER_NAME}" 2>/dev/null || true
fi

# Check if container exists
if ! docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container ${CONTAINER_NAME} not found. Creating and starting it..." >&2

    # Pull the image if not present
    if ! docker image inspect "${IMAGE}" > /dev/null 2>&1; then
        echo "Pulling image ${IMAGE}..." >&2
        docker pull "${IMAGE}"
    fi

    # Create and start the container
    # Required env vars: JIRA_EMAIL, JIRA_API_TOKEN, JIRA_URL
    docker run -d --name "${CONTAINER_NAME}" --restart=unless-stopped \
        --label "last_used=$(date +%s)" \
        --label "auto_cleanup=true" \
        -p 127.0.0.1:9000:9000 \
        -e JIRA_URL="${JIRA_URL}" \
        -e JIRA_USERNAME="${JIRA_EMAIL}" \
        -e JIRA_PERSONAL_TOKEN="${JIRA_API_TOKEN}" \
        -e ENABLED_TOOLS="jira_search,jira_get_issue,jira_create_issue,jira_update_issue,jira_add_comment" \
        -e READ_ONLY_MODE="false" \
        "${IMAGE}" \
        --transport streamable-http --port 9000

    # Wait for container to be ready
    sleep 3
fi

# Check if container is running
if ! docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container ${CONTAINER_NAME} exists but not running. Starting it..." >&2
    docker start "${CONTAINER_NAME}"
    sleep 2
fi

# Connect to the running container with stdio transport
exec docker exec -i "${CONTAINER_NAME}" /app/.venv/bin/mcp-atlassian --transport stdio
