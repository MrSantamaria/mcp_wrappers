#!/bin/bash

# MCP Container Auto-Cleanup Script
# Removes containers labeled with auto_cleanup=true after idle timeout

# Configurable timeout (default: 60 minutes = 3600 seconds)
IDLE_TIMEOUT_SECONDS="${MCP_IDLE_TIMEOUT:-3600}"

# Find containers with auto_cleanup label
for container in $(docker ps --filter "label=auto_cleanup=true" --format "{{.Names}}"); do
    # Get last_used timestamp from label
    last_used=$(docker inspect --format '{{index .Config.Labels "last_used"}}' "$container" 2>/dev/null)

    if [[ -n "$last_used" && "$last_used" != "<no value>" ]]; then
        current_time=$(date +%s)
        idle_seconds=$((current_time - last_used))

        if [[ $idle_seconds -gt $IDLE_TIMEOUT_SECONDS ]]; then
            idle_minutes=$((idle_seconds / 60))
            echo "Stopping idle container: $container (idle for ${idle_minutes} minutes)" >&2
            docker stop "$container" >/dev/null 2>&1
            docker rm "$container" >/dev/null 2>&1
        fi
    fi
done
