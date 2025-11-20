{ config, lib, pkgs, modulesPath, self, ... }:

let
  # 🔥 修正ポイント：config.system → pkgs.system
  docusaurusSite = self.packages.${pkgs.system}.docusaurusSite;
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
  networking.firewall.allowedTCPPorts = [ 80 ];

  # SSH (元設定を維持)
  services.openssh = {
    enable = true;

    # 24.11 で仕様変更：これが新しい正しい場所
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # ブートローダ（元設定ベース）
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # ユーザー定義
  users.users.mtdnot = {
    isNormalUser = true;
    home = "/home/mtdnot";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
  };

  ##############################################
  # Apache Web Server
  ##############################################
  services.httpd = {
    enable = true;

    extraModules = [ "rewrite" ];

    virtualHosts = {
      "localhost" = {
        documentRoot = "/var/www";
        extraConfig = ''
          DirectoryIndex index.html
          <Directory "/var/www">
            Require all granted
            Options FollowSymLinks
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

          # ==========
          # Docusaurus
          # ==========
          Alias /docs ${docusaurusSite}

          <Directory "${docusaurusSite}">
            Require all granted
            Options FollowSymLinks

            # --- SPA 向けルーティング ---
            RewriteEngine On
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule ^ index.html [L]
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
  ];

  system.stateVersion = "24.11";
}
