#!/usr/bin/env bash
set -e
# 推奨: sudo -H -E bash …/deploy-to-nas.sh
#   -H で HOME=/root にし Nix の「$HOME が自分のものでない」警告を減らす。
#   -E で NIX_SSHOPTS を渡す（sudoers で許可されている場合）。

# このリポジトリの flake を常に参照（cwd に依存しない）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 設定
TARGET_HOST="192.168.11.12"
TARGET_USER="nixos"

# sudo だと HOME が mtdnot のまま残り「root が mtdnot の家を所有していない」警告になる。
# SSH は実効ユーザー(root)の known_hosts を見るため、ホスト鍵は /root/.ssh に無く失敗しがち。
# → 鍵と known_hosts は「呼び出し元ユーザー」(SUDO_USER) 基準で揃える。
if [ -n "${SUDO_USER:-}" ] && [ "$(id -u)" -eq 0 ]; then
  DEPLOY_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
  DEPLOY_HOME="$HOME"
fi
SSH_KEY="${DEPLOY_HOME}/.ssh/my-key.pem"
KNOWN_HOSTS="${DEPLOY_HOME}/.ssh/known_hosts"

# IdentitiesOnly: ssh-agent の鍵を全部試して Too many authentication failures になるのを防ぐ
NIX_SSHOPTS_DEFAULT="-i ${SSH_KEY} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
if [ -f "$KNOWN_HOSTS" ]; then
  NIX_SSHOPTS_DEFAULT+=" -o UserKnownHostsFile=${KNOWN_HOSTS}"
fi
export NIX_SSHOPTS="${NIX_SSHOPTS:-$NIX_SSHOPTS_DEFAULT}"
# エージェントの鍵が先に試され MaxAuthTries に達するのを防ぐ（IdentitiesOnly だけでは足りない環境がある）
unset SSH_AUTH_SOCK
FLAKE_TARGET="${SCRIPT_DIR}#nas"

echo "🚀 Starting deployment to $TARGET_HOST"

# ビルド
echo "📦 Building on local machine (103)..."
nixos-rebuild build --flake "$FLAKE_TARGET"

# デプロイ
# --build-host localhost を付けると nixos-rebuild が ssh 経由で自ホストに入り直し、
# その中から nix-copy-closure --to TARGET を実行するため、NIX_SSHOPTS (鍵指定) が
# 内側の ssh まで伝搬せず「Too many authentication failures」で落ちる。
# ローカルビルドのままリモートへ push したいだけなので --build-host は付けない。
echo "📤 Deploying to $TARGET_HOST..."
nixos-rebuild switch \
  --flake "$FLAKE_TARGET" \
  --target-host "$TARGET_USER@$TARGET_HOST" \
  --use-remote-sudo

echo "✅ Deployment complete!"
