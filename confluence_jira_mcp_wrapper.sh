#!/bin/bash

# Jira MCP Wrapper Script
# This script ensures the Jira MCP container is running and connects to it

CONTAINER_NAME="jira-mcp"
IMAGE="ghcr.io/sooperset/mcp-atlassian:latest"

# Check if container exists
if ! podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container ${CONTAINER_NAME} not found. Creating and starting it..." >&2
    
    # Pull the image if not present
    if ! podman image exists "${IMAGE}"; then
        echo "Pulling image ${IMAGE}..." >&2
        podman pull "${IMAGE}"
    fi
    
    # Create and start the container
    # Required env vars: JIRA_EMAIL (your full email address) and JIRA_API_TOKEN
    podman run -d --name "${CONTAINER_NAME}" --restart=unless-stopped \
        -p 127.0.0.1:9000:9000 \
        -e JIRA_URL="https://issues.redhat.com" \
        -e JIRA_USERNAME="${JIRA_EMAIL}" \
        -e JIRA_PERSONAL_TOKEN="${JIRA_API_TOKEN}" \
        -e ENABLED_TOOLS="jira_search,jira_get_issue,jira_create_issue,jira_update_issue,jira_add_comment" \
        -e READ_ONLY_MODE="false" \
	-e MCP_VERY_VERBOSE=true \
	-e MCP_LOGGING_STDOUT=true \
        "${IMAGE}" \
        --transport streamable-http --port 9000 -vv
    
    # Wait for container to be ready
    sleep 3
fi

# Check if container is running
if ! podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container ${CONTAINER_NAME} exists but not running. Starting it..." >&2
    podman start "${CONTAINER_NAME}"
    sleep 2
fi

# Connect to the running container with stdio transport
exec podman exec -i "${CONTAINER_NAME}" /app/.venv/bin/mcp-atlassian --transport stdio
