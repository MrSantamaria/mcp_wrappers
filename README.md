# MCP Wrappers

Container wrapper scripts for Model Context Protocol (MCP) servers.

## Overview

This repository contains wrapper scripts that simplify running MCP servers in containers using Docker. These scripts handle container lifecycle management (creation, starting, and connection) automatically.

## Scripts

### confluence_jira_mcp_wrapper.sh

Wrapper script for the Atlassian MCP server that provides Jira integration capabilities.

**Features:**
- Automatically pulls and creates the container if it doesn't exist
- Starts the container if it's stopped
- Connects to the container using MCP stdio transport
- Supports Jira operations: search, get issue, create issue, update issue, and add comment

**Prerequisites:**

**Configuration Reference:**

All configuration is done through environment variables:

| Variable | Required | Example | Description |
|----------|----------|---------|-------------|
| `JIRA_EMAIL` | Yes | `user@example.com` | Your Jira account email |
| `JIRA_API_TOKEN` | Yes | `ATPA...` | Personal API token from Jira |
| `JIRA_URL` | Yes | `https://company.atlassian.net` | Your Jira instance URL |

**Important:** Make the script executable:
```bash
chmod +x confluence_jira_mcp_wrapper.sh
```

**Get your Jira API token:**
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Copy the token value

**Setup for Claude Code & Cursor:**

This wrapper is designed to share a single container across multiple MCP clients (Claude Code, Cursor, etc.). The container runs in the background and each client connects to it via stdio transport.

1. **Set environment variables** (add to your shell profile like `~/.zshrc` or `~/.bashrc`):
   ```bash
   export JIRA_EMAIL="your.email@example.com"
   export JIRA_API_TOKEN="your-api-token-here"
   export JIRA_URL="https://your-company.atlassian.net"  # Required: Your Jira instance URL
   ```

2. **Configure Claude Code** (`~/.config/claude/claude_desktop_config.json`):
   ```json
   {
     "mcpServers": {
       "jira": {
         "command": "/path/to/mcp_wrappers/confluence_jira_mcp_wrapper.sh"
       }
     }
   }
   ```

3. **Configure Cursor** (Settings → Features → MCP or `.cursor/mcp.json`):
   ```json
   {
     "mcpServers": {
       "jira": {
         "command": "/path/to/mcp_wrappers/confluence_jira_mcp_wrapper.sh"
       }
     }
   }
   ```

**How it works:**
- First client to connect will create and start the container
- Subsequent clients connect to the same running container
- No container restarts needed when switching between Claude Code and Cursor
- Each client gets its own stdio connection to the container

**Manual Usage:**

```bash
export JIRA_EMAIL="your.email@example.com"
export JIRA_API_TOKEN="your-api-token-here"
export JIRA_URL="https://your-company.atlassian.net"
./confluence_jira_mcp_wrapper.sh
```

**Configuration:**

The script is configured for:
- Container image: `ghcr.io/sooperset/mcp-atlassian:latest`
- Container name: `jira-mcp`
- Jira URL: Configurable via `JIRA_URL` environment variable
- Port binding: `127.0.0.1:9000:9000`
- Enabled tools: jira_search, jira_get_issue, jira_create_issue, jira_update_issue, jira_add_comment
- Read-only mode: disabled

### gmail_mcp_wrapper.sh

Wrapper script for the Gmail MCP server that provides Gmail integration capabilities.

**Features:**
- Automatically pulls and creates the container if it doesn't exist
- Starts the container if it's stopped
- Connects to the container using MCP stdio transport
- Supports Gmail operations: search, read, send, draft, labels, filters, and attachments
- Auto-cleanup after 60 minutes of inactivity

**Prerequisites:**

Gmail credentials must be set up in a Docker volume:
1. Create the Docker volume: `docker volume create mcp-gmail`
2. Copy your `credentials.json` file to the volume (obtained from Google Cloud Console with Gmail API enabled)

**Setup for Claude Code & Cursor:**

This wrapper is designed to share a single container across multiple MCP clients (Claude Code, Cursor, etc.). The container runs in the background and each client connects to it via stdio transport.

1. **Configure Claude Code** (`~/.claude/settings.json`):
   ```json
   {
     "mcpServers": {
       "gmail": {
         "command": "/path/to/mcp_wrappers/gmail_mcp_wrapper.sh"
       }
     }
   }
   ```

2. **Configure Cursor** (Settings → Features → MCP or `.cursor/mcp.json`):
   ```json
   {
     "mcpServers": {
       "gmail": {
         "command": "/path/to/mcp_wrappers/gmail_mcp_wrapper.sh"
       }
     }
   }
   ```

**How it works:**
- First client to connect will create and start the container
- Subsequent clients connect to the same running container
- No container restarts needed when switching between Claude Code and Cursor
- Each client gets its own stdio connection to the container
- Container auto-cleanup after 60 minutes of inactivity

**Configuration:**

The script is configured for:
- Container image: `mcp/gmail`
- Container name: `gmail-mcp`
- Volume mount: `mcp-gmail:/gmail-server`
- Credentials path: `/gmail-server/credentials.json`
- Debug logging: enabled (`DEBUG=*`)

## Container Auto-Cleanup

MCP containers use persistent mode for fast reconnection but automatically cleanup after idle time:

**How it works:**
- Containers stay running while actively used
- After 60 minutes of inactivity, automatically removed
- Next Claude session recreates them instantly

**Configure idle timeout:**
```bash
export MCP_IDLE_TIMEOUT=3600  # seconds (default: 1 hour)
```

**Setup automatic cleanup (recommended):**
1. Make cleanup script executable (already done): `chmod +x cleanup_idle_containers.sh`
2. Load launchd service:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.user.mcp-cleanup.plist
   ```
3. Verify it's running:
   ```bash
   launchctl list | grep mcp-cleanup
   ```

**Alternative manual cleanup:**
Run the cleanup script when needed:
```bash
./cleanup_idle_containers.sh
```

**Check running containers:**
```bash
docker ps --filter "label=auto_cleanup=true"
```

**Disable auto-cleanup:**
```bash
launchctl unload ~/Library/LaunchAgents/com.user.mcp-cleanup.plist
```

## Requirements

- Docker installed and configured
- Network access to pull container images
- Valid Jira credentials, API token, and URL (for Jira wrapper)
- Google Cloud credentials with Gmail API enabled (for Gmail wrapper)

## Troubleshooting

### Jira Wrapper Issues

**"Connection refused" or JSON parse errors:**
- Ensure environment variables are set: `env | grep JIRA`
- Verify script is executable: `ls -la *.sh`
- Test credentials: `curl -u $JIRA_EMAIL:$JIRA_API_TOKEN $JIRA_URL/rest/api/3/myself`

**Script not found or permission denied:**
- Make it executable: `chmod +x confluence_jira_mcp_wrapper.sh`
- Use absolute path in Claude Code config: `~/.claude.json`

**Container won't start:**
- Check logs: `docker logs jira-mcp`
- Remove and recreate: `docker rm -f jira-mcp` then restart Claude Code

**Environment variable errors:**
- Check all three variables are set: `JIRA_EMAIL`, `JIRA_API_TOKEN`, `JIRA_URL`
- Reload your shell profile: `source ~/.zshrc` (or `~/.bashrc`)
- Verify JIRA_URL format: Must start with `http://` or `https://`

## Notes

- Containers are configured with `--restart=unless-stopped` for automatic restarts (Jira only)
- The wrappers use stdio transport for MCP communication
- Environment variable validation ensures clear error messages on misconfiguration
