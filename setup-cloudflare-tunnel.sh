#!/usr/bin/env bash

# Cloudflare Tunnel SSH セットアップスクリプト
set -e

echo "========================================="
echo "Cloudflare Tunnel SSH セットアップ"
echo "========================================="
echo ""

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Cloudflareアカウントにログイン
echo -e "${YELLOW}ステップ 1: Cloudflareアカウントにログイン${NC}"
echo "ブラウザが開きます。Cloudflareアカウントでログインしてください。"
cloudflared tunnel login

# 2. トンネル作成
echo ""
echo -e "${YELLOW}ステップ 2: トンネルの作成${NC}"
read -p "トンネル名を入力してください (デフォルト: nixos-ssh): " TUNNEL_NAME
TUNNEL_NAME=${TUNNEL_NAME:-nixos-ssh}

cloudflared tunnel create $TUNNEL_NAME

# トンネルIDを取得
TUNNEL_ID=$(cloudflared tunnel list --name $TUNNEL_NAME --output json | jq -r '.[0].id')

if [ -z "$TUNNEL_ID" ]; then
    echo -e "${RED}エラー: トンネルIDを取得できませんでした${NC}"
    exit 1
fi

echo -e "${GREEN}トンネル作成成功: $TUNNEL_NAME (ID: $TUNNEL_ID)${NC}"

# 3. DNSレコードの設定
echo ""
echo -e "${YELLOW}ステップ 3: DNSレコードの設定${NC}"
read -p "SSH接続用のホスト名を入力してください (例: ssh.example.com): " HOSTNAME

if [ -z "$HOSTNAME" ]; then
    echo -e "${RED}エラー: ホスト名が必要です${NC}"
    exit 1
fi

cloudflared tunnel route dns $TUNNEL_NAME $HOSTNAME

# 4. 設定ファイルの作成
echo ""
echo -e "${YELLOW}ステップ 4: 設定ファイルの作成${NC}"

CONFIG_DIR="$HOME/.cloudflared"
mkdir -p $CONFIG_DIR

cat > $CONFIG_DIR/config.yml <<EOF
tunnel: $TUNNEL_ID
credentials-file: $CONFIG_DIR/$TUNNEL_ID.json

ingress:
  - hostname: $HOSTNAME
    service: ssh://localhost:22
  - service: http_status:404
EOF

echo -e "${GREEN}設定ファイル作成: $CONFIG_DIR/config.yml${NC}"

# 5. NixOS設定の更新案を表示
echo ""
echo -e "${YELLOW}ステップ 5: NixOS設定の更新${NC}"
echo ""
echo "以下の設定を /home/mtdnot/nix/hosts/nixos-cui/configuration.nix に追加してください:"
echo ""
echo -e "${GREEN}----------------------------------------${NC}"
cat <<EOF
  # Cloudflare Tunnel SSH設定
  imports = [
    ../../modules/nixos/cloudflare-tunnel.nix
  ];

  services.cloudflare-tunnel = {
    enable = true;
    tunnelName = "$TUNNEL_NAME";
    tunnelCredentialsFile = "$CONFIG_DIR/$TUNNEL_ID.json";
    hostname = "$HOSTNAME";
  };
EOF
echo -e "${GREEN}----------------------------------------${NC}"

# 6. SSH クライアント設定の案内
echo ""
echo -e "${YELLOW}ステップ 6: SSHクライアント側の設定${NC}"
echo ""
echo "クライアント側で cloudflared をインストールして、以下のコマンドで接続できます:"
echo ""
echo -e "${GREEN}# Macの場合:${NC}"
echo "brew install cloudflare/cloudflare/cloudflared"
echo ""
echo -e "${GREEN}# ~/.ssh/config に追加:${NC}"
cat <<EOF
Host $TUNNEL_NAME
    Hostname $HOSTNAME
    User mtdnot
    ProxyCommand cloudflared access ssh --hostname %h
EOF
echo ""
echo -e "${GREEN}# 接続コマンド:${NC}"
echo "ssh $TUNNEL_NAME"
echo ""
echo "========================================="
echo -e "${GREEN}セットアップ完了！${NC}"
echo "nixos-rebuild switch を実行してサービスを起動してください。"
echo "========================================="