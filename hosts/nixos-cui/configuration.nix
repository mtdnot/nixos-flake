{ config, lib, pkgs, modulesPath, self, ... }:

let
  # 🔥 修正ポイント：config.system → pkgs.system
#  docusaurusSite = self.packages.${pkgs.system}.docusaurusSite;
in
{
  # 共通設定をインポート
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
  ];

  ############################
  # CUI 固有設定
  ############################

  # non-free パッケージ許可
  nixpkgs.config.allowUnfree = true;

  # セキュリティ脆弱性のあるパッケージを許可（一時的な対処）
  nixpkgs.config.permittedInsecurePackages = [
    "emacs-pgtk-with-packages-29.4"
  ];

  # ブートローダ
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Samba マウント設定
  fileSystems."/mnt/samba" = {
    device = "//192.168.11.19/data";
    fsType = "cifs";
    options = [
      "credentials=/root/.smbcredentials"
      "uid=1000"
      "gid=100"
      "file_mode=0644"
      "dir_mode=0755"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=10s"
      "x-systemd.mount-timeout=10s"
    ];
  };

  # mtdnot ユーザーに samba グループを追加
  users.users.mtdnot.extraGroups = [ "wheel" "networkmanager" "audio" "video" "docker" "samba" ];

  # CUI 固有のファイアウォール設定（Samba用）
  networking.firewall.allowedTCPPorts = [ 80 445 3000 5173 8765 ];  # 445: Samba
  networking.firewall.allowedUDPPorts = [ 137 138 ];  # Samba

  ##############################################
  # Samba File Server
  ##############################################
  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;

    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "NixOS Samba Server";
        "netbios name" = "nixos-cui";
        security = "user";
        "map to guest" = "never";

        # ログ設定
        "log file" = "/var/log/samba/log.%m";
        "max log size" = 50;
      };

      # ホームディレクトリ共有
      homes = {
        path = "/home/%S";
        browseable = false;
        writable = true;
        "valid users" = "%S";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      # 共有フォルダ
      shared = {
        path = "/srv/samba/shared";
        browseable = true;
        writable = true;
        "valid users" = "mtdnot";
        "create mask" = "0664";
        "directory mask" = "0775";
        comment = "Shared folder";
      };

      # パブリック読み取り専用フォルダ
      public = {
        path = "/srv/samba/public";
        browseable = true;
        "read only" = true;
        "guest ok" = false;
        "valid users" = "mtdnot";
        comment = "Public read-only folder";
      };
    };
  };

  # Samba用のディレクトリ作成
  systemd.tmpfiles.rules = [
    "d /srv/samba/shared 0775 root samba - -"
    "d /srv/samba/public 0755 root samba - -"
    "d /mnt/samba 0755 root root - -"
    # 開発用ディレクトリを作成（Apacheアクセス用）
    "d /srv/dev 0755 mtdnot users - -"
  ];

  # ~/dev ディレクトリを /srv/dev に同期するサービス
  systemd.services.sync-dev-dir = {
    description = "Sync ~/dev to /srv/dev for Apache access";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "mtdnot";
      ExecStart = "${pkgs.rsync}/bin/rsync -av --delete /home/mtdnot/dev/ /srv/dev/";
    };
  };

  # ファイル変更を監視して自動同期するサービス
  systemd.services.watch-dev-dir = {
    description = "Watch and sync ~/dev changes to /srv/dev";
    wantedBy = [ "multi-user.target" ];
    after = [ "sync-dev-dir.service" ];

    serviceConfig = {
      Type = "simple";
      User = "mtdnot";
      ExecStart = "${pkgs.writeShellScript "watch-dev" ''
        ${pkgs.inotify-tools}/bin/inotifywait -mr \
          -e modify,create,delete,move \
          /home/mtdnot/dev/ \
          --format '%w%f %e' |
        while read file event; do
          ${pkgs.rsync}/bin/rsync -av --delete /home/mtdnot/dev/ /srv/dev/
        done
      ''}";
      Restart = "always";
    };
  };

  ##############################################
  # Apache Web Server
  ##############################################
  services.httpd = {
    enable = true;

    extraModules = [ "rewrite" "alias" ];

    virtualHosts = {
      "localhost" = {
        documentRoot = "/var/www";
        extraConfig = ''
          DirectoryIndex index.html
          <Directory "/var/www">
            Require all granted
            Options FollowSymLinks
          </Directory>

          # ~/dev ディレクトリのエイリアス設定（LAN内アクセスのみ）
          Alias "/dev" "/srv/dev"

          <Directory "/srv/dev">
            Options Indexes FollowSymLinks
            AllowOverride None

            # LAN内（192.168.11.0/24）とローカルホストからのみアクセス許可
            Require ip 192.168.11.0/24
            Require ip 127.0.0.1
            Require ip ::1

            # ディレクトリ一覧表示を有効化（必要に応じて）
            Options +Indexes

            # .htaccess ファイルを使用可能にする（必要に応じて）
            AllowOverride All
          </Directory>
        '';
      };

      "mtdnot.dev" = {
        documentRoot = "/var/www";

        extraConfig = ''
          DirectoryIndex index.html
          <Directory "/var/www">
            Require all granted
            Options FollowSymLinks
          </Directory>

          # ~/dev ディレクトリのエイリアス設定（LAN内アクセスのみ）
          Alias "/dev" "/srv/dev"

          <Directory "/srv/dev">
            Options Indexes FollowSymLinks
            AllowOverride None

            # LAN内（192.168.11.0/24）とローカルホストからのみアクセス許可
            Require ip 192.168.11.0/24
            Require ip 127.0.0.1
            Require ip ::1

            # ディレクトリ一覧表示を有効化
            Options +Indexes

            # .htaccess ファイルを使用可能にする
            AllowOverride All
          </Directory>
        '';
      };

      # Homelab Dashboard - 内部ネットワークのみアクセス可能
      "homelab.local" = {
        documentRoot = "/var/www/homelab";

        extraConfig = ''
          DirectoryIndex index.html

          <Directory "/var/www/homelab">
            Options FollowSymLinks
            AllowOverride None

            # 192.168.11.0/24 ネットワークからのみアクセス許可
            Require ip 192.168.11.0/24
            Require ip 127.0.0.1
            Require ip ::1
          </Directory>
        '';
      };

      # txt2md.mtdnot.dev - Text to Markdown converter
      "txt2md.mtdnot.dev" = {
        documentRoot = "/var/www/txt2md";

        extraConfig = ''
          DirectoryIndex index.html

          <Directory "/var/www/txt2md">
            Require all granted
            Options FollowSymLinks
            AllowOverride None
          </Directory>
        '';
      };
    };
  };

  # CUI 固有のシステムパッケージ
  environment.systemPackages = with pkgs; [
    cifs-utils
    cloudflared         # Cloudflare Tunnel クライアント
    flyctl              # Fly.io CLI
  ];

  # Cloudflare Tunnel Service for SSH Access
  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel for SSH";
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

      # 環境変数
      Environment = [
        "HOME=/home/mtdnot"
      ];
    };
  };
}
