# ============================================================
# ai-enclave — Secure AI Agent Development Environment
# Ubuntu 24.04 Base
# ============================================================
FROM ubuntu:24.04

# Build args
ARG NODE_VERSION=22

# Non-interactive
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo
ENV LANG=ja_JP.UTF-8

# ============================================================
# Layer 1: System base (change frequency: low)
# ============================================================
RUN apt-get update && apt-get install -y \
    curl wget git vim nano less \
    tmux \
    python3 python3-pip python3-venv \
    gnupg ca-certificates \
    openssh-client \
    jq fzf ripgrep fd-find \
    locales tzdata inotify-tools socat \
    && locale-gen ja_JP.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Layer 2: Node.js
# ============================================================
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Layer 3: Claude Code CLI
# ============================================================
RUN npm install -g @anthropic-ai/claude-code

# ============================================================
# Layer 4: GitHub CLI (gh)
# ============================================================
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ============================================================
# Layer 5: Bitwarden CLI (bw)
# ============================================================
RUN npm install -g @bitwarden/cli

# ============================================================
# Layer 6: Python libraries
# ============================================================
RUN pip3 install --no-cache-dir --break-system-packages \
    pyyaml \
    requests

# ============================================================
# Layer 7: code-server (browser-based VS Code)
# ============================================================
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ============================================================
# Layer 8: User setup
# ============================================================
RUN userdel -r ubuntu 2>/dev/null || true \
    && useradd -m -s /bin/bash -u 1000 agent \
    && mkdir -p /home/agent/.claude \
    && chown -R agent:agent /home/agent

# ============================================================
# Layer 9: Workspace + intel
# ============================================================
WORKDIR /workspace
RUN chown agent:agent /workspace \
    && mkdir -p /intel && chown agent:agent /intel

USER agent

# No entrypoint — transparent operation
CMD ["/bin/bash"]
