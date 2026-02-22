{ config, lib, pkgs, modulesPath, self, ... }:

let
  # 🔥 修正ポイント：config.system → pkgs.system
#  docusaurusSite = self.packages.${pkgs.system}.docusaurusSite;
in
{
  # ハードウェア構成
  imports = [
    ./hardware-configuration.nix
  ];

  # Nix コマンド / flake 有効化
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # non-free パッケージ許可（元設定を継承）
  nixpkgs.config.allowUnfree = true;

  # セキュリティ脆弱性のあるパッケージを許可（一時的な対処）
  nixpkgs.config.permittedInsecurePackages = [
    "emacs-pgtk-with-packages-29.4"
  ];

  # バイナリ互換 (glibc まわり) - 元の設定を維持
  programs.nix-ld.enable = true;

  # ロケール・タイムゾーン（元どおり）
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "ja_JP.UTF-8";

  # IME 設定（無効化された状態で構造だけ維持）
  i18n.inputMethod = {
    type = "fcitx5";
    enable = false;
    fcitx5 = {
      addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
      ];
    };
  };

  # ネットワーク（元設定ベース）
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 445 3000 5173 8765 ];  # 3000: Context Keeper, 5173: Vite Dev Server, 8765: MAS API Server (Hono)
  networking.firewall.allowedUDPPorts = [ 137 138 ];

  # SSH (元設定を維持)
  services.openssh = {
    enable = true;

    # 24.11 で仕様変更：これが新しい正しい場所
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
    };
  };

  # ブートローダ（元設定ベース）
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


  # ユーザー定義
  users.users.mtdnot = {
    isNormalUser = true;
    home = "/home/mtdnot";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "docker" "samba" ];
  };

  # nixos-rebuild を NOPASSWD で実行可能にする
  security.sudo.extraRules = [{
    users = [ "mtdnot" ];
    commands = [
      { command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
    ];
  }];

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

  # CUI 側で最低限ほしいツール（OS レベル）
  environment.systemPackages = with pkgs; [
    git
    tmux
    htop
    neofetch
    zsh
    pciutils
    terraform
    cifs-utils
    awscli2             # AWS CLI v2
    cloudflared         # Cloudflare Tunnel クライアント
    jdk21               # Java 21
    flyctl              # Fly.io CLI
  ];


  ############################
  # NVIDIA GPU 用設定
  ############################



  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # ← 32bit ライブラリも入れる
  };


  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.blacklistedKernelModules = [ "nouveau" ];

  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
  };

  # これは enableNvidia が内部で面倒を見てくれるので、いったん消してもいい
  # hardware.nvidia-container-toolkit.enable = true;



  hardware.nvidia-container-toolkit.enable = true;

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

  # nixos-rebuild switch 実行後に shell 設定を自動的に再読み込み
  system.activationScripts.sourceShellConfigs = lib.stringAfter [ "users" ] ''
    # 各ユーザーのシェル設定を再読み込みするスクリプトを作成
    for user_home in /home/*; do
      if [ -d "$user_home" ]; then
        username=$(basename "$user_home")

        # bashrc と zshrc のソースを促すメッセージを表示
        echo "Shell configuration files have been updated for user: $username"
        echo "Please run one of the following commands in your terminal:"
        echo "  source ~/.bashrc  (for bash users)"
        echo "  source ~/.zshrc   (for zsh users)"

        # ユーザーの現在のシェルセッションには直接影響を与えられないため、
        # 新しいシェルセッションで自動的に読み込まれることを通知
        echo "Note: New shell sessions will automatically use the updated configuration."
      fi
    done
  '';

  system.stateVersion = "24.11";
}
