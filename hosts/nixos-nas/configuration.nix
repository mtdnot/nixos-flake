{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
  ];

  ############################
  # NAS 基本設定
  ############################

  # ホスト名
  networking.hostName = "nixos-nas";

  # non-free パッケージ許可（Jellyfin等で必要）
  nixpkgs.config.allowUnfree = true;

  # タイムゾーン
  time.timeZone = "Asia/Tokyo";

  # ブートローダ設定
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ユーザー設定
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "samba" "jellyfin" ];
    openssh.authorizedKeys.keys = [
      # ここにSSH公開鍵を追加
      # "ssh-rsa AAAAB3NzaC1yc2E..."
    ];
  };

  users.users.mtdnot = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "samba" "jellyfin" ];
  };

  ############################
  # ストレージ・ファイルシステム設定
  ############################

  # メディアファイル用ディレクトリ作成
  systemd.tmpfiles.rules = [
    # Samba共有ディレクトリ
    "d /srv/samba/media 0775 nixos samba - -"
    "d /srv/samba/music 0775 nixos samba - -"
    "d /srv/samba/photos 0775 nixos samba - -"
    "d /srv/samba/documents 0775 nixos samba - -"
    "d /srv/samba/backup 0775 nixos samba - -"

    # メディアサーバー用ディレクトリ
    "d /mnt/media 0755 root root - -"
    "d /mnt/media/movies 0755 jellyfin jellyfin - -"
    "d /mnt/media/tv 0755 jellyfin jellyfin - -"
    "d /mnt/media/music 0755 navidrome navidrome - -"
    "d /mnt/media/photos 0755 jellyfin jellyfin - -"

    # バックアップディレクトリ
    "d /srv/backup 0700 root root - -"
  ];

  ############################
  # Samba ファイル共有サーバー
  ############################
  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;

    # Sambaパッケージの拡張機能を有効化
    extraConfig = ''
      workgroup = WORKGROUP
      server string = NixOS NAS Server
      netbios name = nixos-nas
      security = user
      map to guest = never

      # パフォーマンス最適化
      socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=524288 SO_SNDBUF=524288
      read raw = yes
      write raw = yes
      max xmit = 65535
      dead time = 15
      getwd cache = yes

      # ログ設定
      log file = /var/log/samba/log.%m
      max log size = 50
      log level = 1
    '';

    shares = {
      # メディアファイル共有（読み書き可能）
      media = {
        path = "/srv/samba/media";
        browseable = "yes";
        writable = "yes";
        "valid users" = "nixos mtdnot";
        "create mask" = "0664";
        "directory mask" = "0775";
        comment = "Media files (videos, movies, TV shows)";
      };

      # 音楽ファイル共有
      music = {
        path = "/srv/samba/music";
        browseable = "yes";
        writable = "yes";
        "valid users" = "nixos mtdnot";
        "create mask" = "0664";
        "directory mask" = "0775";
        comment = "Music library";
      };

      # 写真共有
      photos = {
        path = "/srv/samba/photos";
        browseable = "yes";
        writable = "yes";
        "valid users" = "nixos mtdnot";
        "create mask" = "0664";
        "directory mask" = "0775";
        comment = "Photo collection";
      };

      # ドキュメント共有
      documents = {
        path = "/srv/samba/documents";
        browseable = "yes";
        writable = "yes";
        "valid users" = "nixos mtdnot";
        "create mask" = "0664";
        "directory mask" = "0775";
        comment = "Document storage";
      };

      # バックアップ専用（管理者のみアクセス可能）
      backup = {
        path = "/srv/backup";
        browseable = "no";
        writable = "yes";
        "valid users" = "nixos";
        "create mask" = "0600";
        "directory mask" = "0700";
        comment = "Backup storage (admin only)";
      };
    };
  };

  # Sambaユーザーパスワード設定の注意書き
  # sudo smbpasswd -a nixos
  # sudo smbpasswd -a mtdnot

  ############################
  # Navidrome 音楽ストリーミング
  ############################
  services.navidrome = {
    enable = true;

    settings = {
      # 基本設定
      Address = "0.0.0.0";
      Port = 4533;

      # 音楽ライブラリのパス
      MusicFolder = "/mnt/media/music";

      # データディレクトリ
      DataFolder = "/var/lib/navidrome";

      # ログレベル
      LogLevel = "info";

      # スキャン間隔（秒）
      ScanSchedule = "@every 1h";

      # トランスコーディング設定
      TranscodingCacheSize = "100MB";

      # UI設定
      UIWelcomeMessage = "Welcome to NixOS NAS Music Server";

      # 外部アクセス用（Cloudflare Tunnel経由を想定）
      BaseURL = "";
    };
  };

  ############################
  # Jellyfin メディアサーバー
  ############################
  services.jellyfin = {
    enable = true;
    openFirewall = true;

    # Jellyfinユーザーをvideoグループに追加（ハードウェアアクセラレーション用）
    user = "jellyfin";
    group = "jellyfin";
  };

  # Jellyfinのポート: 8096 (HTTP), 8920 (HTTPS)

  ############################
  # ファイアウォール設定
  ############################
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      22      # SSH
      80      # HTTP
      139     # Samba
      445     # Samba
      4533    # Navidrome
      8096    # Jellyfin HTTP
      8920    # Jellyfin HTTPS
    ];

    allowedUDPPorts = [
      137     # Samba
      138     # Samba
      1900    # Jellyfin service discovery
      7359    # Jellyfin client discovery
    ];
  };

  ############################
  # システムパッケージ
  ############################
  environment.systemPackages = with pkgs; [
    # ファイルシステム管理
    cifs-utils
    nfs-utils
    e2fsprogs
    ntfs3g
    exfat

    # メディア管理ツール
    ffmpeg
    mediainfo

    # Samba関連
    samba

    # ネットワークツール
    wget
    curl
    rsync

    # 監視・管理
    htop
    iotop
    ncdu

    # Cloudflare Tunnel（外部アクセス用）
    cloudflared
  ];

  ############################
  # SSH サーバー設定
  ############################
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
    };
  };

  ############################
  # 自動バックアップ設定（オプション）
  ############################
  # systemd.services.nas-backup = {
  #   description = "NAS data backup";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.rsync}/bin/rsync -av --delete /srv/samba/ /srv/backup/";
  #   };
  # };
  #
  # systemd.timers.nas-backup = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnCalendar = "daily";
  #     Persistent = true;
  #   };
  # };

  ############################
  # システムバージョン
  ############################
  system.stateVersion = "24.11";
}
