{ config, lib, pkgs, ... }:

{
  # Nix コマンド / flake 有効化
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # non-free パッケージ許可
  nixpkgs.config.allowUnfree = true;

  # セキュリティ脆弱性のあるパッケージを許可（一時的な対処）
  nixpkgs.config.permittedInsecurePackages = [
    "emacs-pgtk-with-packages-29.4"
  ];

  # バイナリ互換 (glibc まわり)
  programs.nix-ld.enable = true;

  # ロケール・タイムゾーン
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

  # ネットワーク基本設定
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 3000 5173 8765 ];  # 3000: Context Keeper, 5173: Vite Dev Server, 8765: MAS API Server
  networking.firewall.allowedUDPPorts = [ ];

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
    };
  };

  # mtdnot ユーザー定義
  users.users.mtdnot = {
    isNormalUser = true;
    home = "/home/mtdnot";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "docker" ];
  };

  # nixos-rebuild を NOPASSWD で実行可能にする
  security.sudo.extraRules = [{
    users = [ "mtdnot" ];
    commands = [
      { command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
    ];
  }];

  # 共通システムパッケージ
  environment.systemPackages = with pkgs; [
    git
    tmux
    htop
    neofetch
    zsh
    pciutils
    terraform
    awscli2             # AWS CLI v2
    jdk21               # Java 21
  ];

  ############################
  # NVIDIA GPU 用設定
  ############################
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
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

  hardware.nvidia-container-toolkit.enable = true;

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
