# mas-secure

Docker化された幕府環境。ファイルシステム隔離により、エージェントの爆発半径をコンテナ内に限定する。

## 設計思想

- **コンテナ = 幕府そのもの**: Ubuntu 24.04 + 全ツールプリセット
- **Windows隔離**: intel(:ro) の1本のみが接触点。workspace はコンテナ専用
- **操作感はWSL2と同じ**: `docker exec -it` → 手動で出陣・daemon起動・tmux attach
- **Secret Daemon**: Bitwarden CLI経由のAPIキー管理。意図的な複雑さを維持

## クイックスタート

```bash
# 1. ビルド & 起動
docker compose build
docker compose up -d

# 2. 入城
docker exec -it shogun-v2 bash

# 3. リポジトリをコンテナ内にclone
git clone https://github.com/<user>/multi-agent-shogun-v2 /workspace/multi-agent-shogun-v2
cd /workspace/multi-agent-shogun-v2

# 4. Claude Code認証（初回のみ）
claude

# 5. 出陣
bash scripts/shutsujin.sh
bash scripts/secret_daemon.sh   # マスターPW入力
tmux attach -t multiagent
```

## ボリューム構成

| ボリューム | 種別 | 用途 |
|-----------|------|------|
| `shogun-workspace` | 名前付き | プロジェクトファイル（コンテナ専用） |
| `shogun-claude-config` | 名前付き | ~/.claude 設定永続化 |
| `C:\intel` → `/intel:ro` | bind | 殿の差し入れ（読み取り専用） |

## セキュリティ

WSL2比較で、CLAUDE.md Tier 1禁止事項の約80%が「ルールベース → 技術的に不可能」に昇格:

- `/mnt/c/` へのアクセス → **物理的に不可能**
- Windowsシステムファイル破壊 → **不可能（隔離）**
- intel → **読み取り専用（:ro）技術的強制**
- 非rootユーザー（shogun:1000）で運用
- `no-new-privileges` セキュリティオプション

## image配布

```bash
# GitHub Container Registry
docker build -t ghcr.io/<user>/mas-secure:latest .
docker push ghcr.io/<user>/mas-secure:latest
```

## 関連

- 計画書: [multi-agent-shogun-secure_plan.md](../multi-agent-shogun-v2/docs/multi-agent-shogun-secure_plan.md)
- 大本: [yohey-w/multi-agent-shogun](https://github.com/yohey-w/multi-agent-shogun)
