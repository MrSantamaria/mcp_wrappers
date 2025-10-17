# MCP Wrappers

Container wrapper scripts for Model Context Protocol (MCP) servers.

## Overview

This repository contains wrapper scripts that simplify running MCP servers in containers using Podman. These scripts handle container lifecycle management (creation, starting, and connection) automatically.

## Scripts

### confluence_jira_mcp_wrapper.sh

Wrapper script for the Atlassian MCP server that provides Jira integration capabilities.

**Features:**
- Automatically pulls and creates the container if it doesn't exist
- Starts the container if it's stopped
- Connects to the container using MCP stdio transport
- Supports Jira operations: search, get issue, create issue, update issue, and add comment

**Prerequisites:**

The following environment variables must be set:
- `JIRA_EMAIL` - Your full email address for Jira authentication
- `JIRA_API_TOKEN` - Your Jira personal access token

**Usage:**

```bash
export JIRA_EMAIL="your.email@example.com"
export JIRA_API_TOKEN="your-api-token-here"
./confluence_jira_mcp_wrapper.sh
```

**Configuration:**

The script is configured for:
- Container image: `ghcr.io/sooperset/mcp-atlassian:latest`
- Container name: `jira-mcp`
- Jira URL: `https://issues.redhat.com`
- Port binding: `127.0.0.1:9000:9000`
- Enabled tools: jira_search, jira_get_issue, jira_create_issue, jira_update_issue, jira_add_comment
- Read-only mode: disabled
- Verbose logging: enabled

## Requirements

- Podman installed and configured
- Network access to pull container images
- Valid Jira credentials and API token

## Notes

- Containers are configured with `--restart=unless-stopped` for automatic restarts
- The wrapper uses stdio transport for MCP communication
- Verbose logging is enabled by default for debugging purposes
