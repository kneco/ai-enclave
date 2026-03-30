# ============================================================
# mas-secure — Docker化された幕府環境
# Ubuntu 24.04 ベース
# ============================================================
FROM ubuntu:24.04

# ビルド引数
ARG NODE_VERSION=22

# 非対話モード
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo
ENV LANG=ja_JP.UTF-8

# ============================================================
# Layer 1: システム基盤（変更頻度: 低）
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
# Layer 2: Node.js（Claude Code CLI依存）
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
# Layer 6: Python依存ライブラリ（Secret Daemon等）
# ============================================================
RUN pip3 install --no-cache-dir --break-system-packages \
    pyyaml \
    requests

# ============================================================
# Layer 7: ユーザー設定
# ============================================================
RUN useradd -m -s /bin/bash -u 1000 shogun \
    && mkdir -p /home/shogun/.claude \
    && chown -R shogun:shogun /home/shogun

# ============================================================
# Layer 8: ワークスペース + intel
# ============================================================
WORKDIR /workspace
RUN chown shogun:shogun /workspace \
    && mkdir -p /intel && chown shogun:shogun /intel

USER shogun

# entrypointなし（殿の設計思想: 何をやっているか見える）
CMD ["/bin/bash"]
