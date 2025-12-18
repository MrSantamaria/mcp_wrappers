---
name: credential-check
description: "Scan for leaked credentials, secrets, API keys, and sensitive data"
---

# /credential-check - Credential Leak Scanner

Scan the codebase for accidentally committed credentials, secrets, API keys, tokens, and other sensitive data.

## What to Scan For

Search for these patterns across all files (excluding .git directory):

### API Keys and Tokens
- `api[_-]?key\s*[=:]\s*["']?[a-zA-Z0-9_-]{20,}` - Generic API keys
- `token\s*[=:]\s*["']?[a-zA-Z0-9_-]{20,}` - Generic tokens
- `bearer\s+[a-zA-Z0-9_-]{20,}` - Bearer tokens
- `AKIA[0-9A-Z]{16}` - AWS Access Key IDs
- `ghp_[a-zA-Z0-9]{36}` - GitHub Personal Access Tokens
- `gho_[a-zA-Z0-9]{36}` - GitHub OAuth Tokens
- `sk-[a-zA-Z0-9]{48}` - OpenAI API Keys
- `xox[baprs]-[a-zA-Z0-9-]{10,}` - Slack Tokens

### Passwords and Secrets
- `password\s*[=:]\s*["'][^"']+["']` - Hardcoded passwords
- `secret\s*[=:]\s*["'][^"']+["']` - Hardcoded secrets
- `private[_-]?key` - Private key references
- `-----BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY-----` - Private key files

### Connection Strings and URLs
- `mongodb(\+srv)?://[^/\s]+` - MongoDB connection strings
- `postgres(ql)?://[^/\s]+` - PostgreSQL connection strings
- `mysql://[^/\s]+` - MySQL connection strings
- `redis://[^/\s]+` - Redis connection strings

### Credential Files
Check for existence of these sensitive files:
- `.env` files (except `.env.example`, `.env.template`)
- `credentials.json`
- `*.pem`, `*.key` files
- `id_rsa`, `id_ed25519` (SSH keys)
- `.netrc`, `.npmrc` with credentials
- `config.json` files with auth sections

## Scan Process

1. **File Discovery**: Use Glob to find all relevant files
2. **Pattern Matching**: Use Grep to search for credential patterns
3. **Context Analysis**: Read matched files to verify true positives
4. **Report Generation**: List all findings with file paths and line numbers

## Output Format

For each finding, report:
- **File**: Path to the file
- **Line**: Line number
- **Type**: Category of credential (API Key, Password, Token, etc.)
- **Risk**: HIGH/MEDIUM/LOW based on credential type
- **Recommendation**: Action to take (remove, rotate, use env var)

## Exclusions

Skip scanning:
- `.git/` directory
- `node_modules/`, `vendor/`, `venv/` directories
- Binary files
- Lock files (`package-lock.json`, `yarn.lock`, etc.)
- Example/template files (`.env.example`, `*.sample`)

## After Scanning

If credentials are found:
1. List all findings clearly
2. Recommend immediate actions (rotate compromised credentials)
3. Suggest using environment variables or secrets management
4. Warn about git history if credentials were previously committed
