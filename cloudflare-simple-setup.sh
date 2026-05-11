#!/usr/bin/env bash

# 簡単なCloudflare Tunnel設定スクリプト
set -e

echo "Cloudflare Tunnel セットアップ"
echo "=============================="

# トンネル名設定
TUNNEL_NAME="nixos-ssh"

# 既存のトンネルをチェック
echo "既存のトンネルをチェック中..."
if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo "トンネル '$TUNNEL_NAME' は既に存在します。"
    TUNNEL_ID=$(cloudflared tunnel list --name $TUNNEL_NAME --output json | jq -r '.[0].id')
else
    echo "新しいトンネルを作成中..."
    cloudflared tunnel create $TUNNEL_NAME
    TUNNEL_ID=$(cloudflared tunnel list --name $TUNNEL_NAME --output json | jq -r '.[0].id')
fi

echo "トンネルID: $TUNNEL_ID"

# 設定ディレクトリ作成
CONFIG_DIR="$HOME/.cloudflared"
mkdir -p $CONFIG_DIR

# 設定ファイル作成
cat > $CONFIG_DIR/config.yml <<EOF
tunnel: $TUNNEL_ID
credentials-file: $CONFIG_DIR/$TUNNEL_ID.json

ingress:
  - hostname: ssh-nixos.mtdnot.dev
    service: ssh://localhost:22
  - service: http_status:404
EOF

echo "設定ファイルを作成しました: $CONFIG_DIR/config.yml"

# NixOS設定の更新内容を表示
echo ""
echo "以下の設定を configuration.nix に追加してください："
echo ""
cat <<'EOF'
  # Cloudflare Tunnel Service
  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "notify";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config /home/mtdnot/.cloudflared/config.yml run";
      Restart = "on-failure";
      RestartSec = "5s";
      User = "mtdnot";
      Group = "users";
    };
  };
EOF

echo ""
echo "DNSレコードを設定するには："
echo "cloudflared tunnel route dns $TUNNEL_NAME ssh-nixos.mtdnot.dev"