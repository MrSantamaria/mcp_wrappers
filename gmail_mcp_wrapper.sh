#!/bin/bash

# Gmail MCP Wrapper Script
# This script ensures the Gmail MCP container is running and connects to it

CONTAINER_NAME="gmail-mcp"
IMAGE="mcp/gmail"

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
    docker run -d --name "${CONTAINER_NAME}" --restart=unless-stopped \
        --label "last_used=$(date +%s)" \
        --label "auto_cleanup=true" \
        -v mcp-gmail:/gmail-server \
        -e GMAIL_CREDENTIALS_PATH=/gmail-server/credentials.json \
        -e DEBUG="*" \
        "${IMAGE}"

    # Wait for container to be ready
    sleep 2
fi

# Check if container is running
if ! docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container ${CONTAINER_NAME} exists but not running. Starting it..." >&2
    docker start "${CONTAINER_NAME}"
    sleep 1
fi

# Connect to the running container with stdio transport
exec docker exec -i "${CONTAINER_NAME}" node dist/index.js
