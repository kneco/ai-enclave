# ai-enclave

Secure, isolated AI agent development environment. Containerized with Docker to limit blast radius to the enclave.

## What is this?

A pre-configured Docker environment for AI-assisted development. Clone your repo inside, run Claude Code or other AI tools, and work safely — the container cannot touch your host filesystem (except a read-only data input).

## Pre-installed Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Claude Code CLI | latest | AI coding assistant |
| code-server | latest | Browser-based VS Code (port 8080) |
| GitHub CLI (gh) | latest | GitHub operations |
| Bitwarden CLI (bw) | latest | Secrets management |
| Node.js | 22.x | JavaScript runtime |
| Python 3 | system | Scripting & automation |
| tmux | system | Terminal multiplexer |
| git | system | Version control |
| ripgrep, fd, fzf, jq | system | Search & data processing |

## Quick Start

```bash
# 1. Build & start
docker compose build
docker compose up -d

# 2. Enter the enclave
docker exec -it ai-enclave bash

# 3. Clone your project
git clone https://github.com/<user>/<repo> /workspace/<repo>
cd /workspace/<repo>

# 4. Authenticate Claude Code (first time only)
claude

# 5. Start code-server (optional)
code-server --bind-addr 0.0.0.0:8080 /workspace
# Then open http://localhost:8080 in your browser
```

## Volume Layout

| Volume | Type | Purpose |
|--------|------|---------|
| `enclave-workspace` | Named | Project files (container-only) |
| `enclave-claude-config` | Named | ~/.claude config persistence |
| `/intel` | Bind (read-only) | Data input from host |

## Security

Compared to running AI agents directly on your host:

- **Filesystem isolation**: Cannot access host files outside `/intel` (read-only)
- **Non-root user**: Runs as `agent` (UID 1000)
- **no-new-privileges**: Prevents privilege escalation
- **Named volumes**: Workspace is invisible from host — no accidental host file modification
- **Read-only intel**: Data input is one-way (host → container)

## Host-side Utilities

| File | Purpose |
|------|---------|
| `scripts/ntfy_toast.ps1` | Windows toast notifications via ntfy.sh (PowerShell 5.1+) |

## Image Distribution

```bash
# GitHub Container Registry
docker build -t ghcr.io/<user>/ai-enclave:latest .
docker push ghcr.io/<user>/ai-enclave:latest
```
