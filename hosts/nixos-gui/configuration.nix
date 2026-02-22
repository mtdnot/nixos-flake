{ config, pkgs, lib, nix-openclaw, ... }: {
  # 共通設定をインポート
  imports = [
    # TODO: hardware-configuration.nix を追加してください
    # ./hardware-configuration.nix
    ../../modules/nixos/common.nix
  ];

  ############################
  # GUI 固有設定
  ############################

  # TODO: ブートローダ設定を追加してください
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  # TODO: ファイルシステム設定を追加してください
  # fileSystems."/" = {
  #   device = "/dev/disk/by-uuid/your-uuid";
  #   fsType = "ext4";
  # };

  # Agent ユーザー定義
  users.users.agent = {
    isNormalUser = true;
    description = "Agent User";
    home = "/home/agent";
    extraGroups = [ "wheel" ];  # sudo権限
  };

  # Pass nix-openclaw to home-manager modules
  home-manager.extraSpecialArgs = {
    inherit nix-openclaw;
  };

  # Agent user configuration with OpenClaw
  home-manager.users.agent.imports = [
    ../../modules/users/agent/home.nix
    nix-openclaw.homeManagerModules.openclaw
  ];

  # TODO: GUI 環境設定を追加してください（必要に応じて）
  # services.xserver.enable = true;
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
}
