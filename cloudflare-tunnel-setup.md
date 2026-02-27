# Cloudflare Tunnel SSH セットアップガイド

## 概要
このガイドでは、Cloudflare Tunnel を使って外部から安全にSSH接続できるようにします。

## メリット
- ポート転送不要（ファイアウォールの設定変更不要）
- 動的IPアドレスでも問題なし
- Cloudflareのセキュリティ機能を活用
- 無料プランで利用可能

## セットアップ手順

### 1. Cloudflare アカウントの準備
- [Cloudflare](https://dash.cloudflare.com/) にアカウントを作成
- ドメインを登録（既存のドメインを使うか、新規取得）

### 2. Cloudflare Tunnel の作成

```bash
# Cloudflareにログイン（ブラウザが開きます）
cloudflared tunnel login

# トンネルを作成
cloudflared tunnel create nixos-ssh

# トンネルの確認
cloudflared tunnel list
```

### 3. DNSレコードの追加

```bash
# ssh.yourdomain.com をトンネルにルーティング
cloudflared tunnel route dns nixos-ssh ssh.yourdomain.com
```

### 4. 設定ファイルの作成

```bash
# 設定ディレクトリ作成
mkdir -p ~/.cloudflared

# トンネルIDを確認
cloudflared tunnel list
```

`~/.cloudflared/config.yml` を作成:

```yaml
tunnel: <YOUR-TUNNEL-ID>
credentials-file: /home/mtdnot/.cloudflared/<YOUR-TUNNEL-ID>.json

ingress:
  - hostname: ssh.yourdomain.com
    service: ssh://localhost:22
  - service: http_status:404
```

### 5. NixOS設定の更新

#### 方法A: シンプルな systemd サービス（推奨）

`/home/mtdnot/nix/hosts/nixos-cui/configuration.nix` に追加:

```nix
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
```

#### 方法B: モジュールを使う方法

1. モジュールをインポート:
```nix
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/cloudflare-tunnel.nix
  ];
```

2. サービスを有効化:
```nix
  services.cloudflare-tunnel = {
    enable = true;
    tunnelName = "nixos-ssh";
    tunnelCredentialsFile = "/home/mtdnot/.cloudflared/<TUNNEL-ID>.json";
    hostname = "ssh.yourdomain.com";
  };
```

### 6. 設定を適用

```bash
cd /home/mtdnot/nix
sudo nixos-rebuild switch --flake .#nixos-cui
```

### 7. サービスの確認

```bash
# サービスステータス確認
systemctl status cloudflared

# ログ確認
journalctl -u cloudflared -f
```

## クライアント側の設定

### macOS/Linux

1. cloudflared をインストール:
```bash
# macOS
brew install cloudflare/cloudflare/cloudflared

# Linux
# https://github.com/cloudflare/cloudflared/releases から最新版をダウンロード
```

2. SSH設定 (`~/.ssh/config`):
```
Host nixos-remote
    Hostname ssh.yourdomain.com
    User mtdnot
    ProxyCommand cloudflared access ssh --hostname %h
```

3. 接続:
```bash
ssh nixos-remote
```

### Windows

1. [cloudflared for Windows](https://github.com/cloudflare/cloudflared/releases) をダウンロード
2. SSH設定は同様
3. PowerShell/WSL から接続

## トラブルシューティング

### 接続できない場合

1. トンネルの状態確認:
```bash
cloudflared tunnel list
systemctl status cloudflared
```

2. DNS確認:
```bash
nslookup ssh.yourdomain.com
```

3. ファイアウォール確認:
```bash
sudo firewall-cmd --list-all
```

### ログの確認

```bash
# Cloudflaredのログ
journalctl -u cloudflared -n 50

# SSHのログ
journalctl -u sshd -n 50
```

## セキュリティの推奨事項

1. SSH鍵認証を使う（パスワード認証を無効化）
2. Cloudflare Access を設定して追加の認証層を追加
3. 定期的にトンネルの認証情報を更新

## 便利な追加設定

### 複数サービスの公開

`config.yml` を編集して他のサービスも追加可能:

```yaml
ingress:
  - hostname: ssh.yourdomain.com
    service: ssh://localhost:22
  - hostname: web.yourdomain.com
    service: http://localhost:80
  - service: http_status:404
```

### Cloudflare Access による保護

Cloudflare Dashboard から Access ポリシーを設定して、
メールアドレスやGoogleアカウントでの認証を追加できます。