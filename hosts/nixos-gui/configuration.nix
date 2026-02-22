{ config, pkgs, lib, nix-openclaw, ... }:

let
  # Windsurf specific nixpkgs
  nixpkgs-windsurf = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/fe51d34885f7b5e3e7b59572796e1bcb427eccb1.tar.gz";
    sha256 = "0pg3ibyagan1y57l1q1rwyrygrwg02p59p0fbgl23hf1nw58asda";
  };

  windsurf = (import nixpkgs-windsurf {
    inherit (pkgs) system;
    config.allowUnfree = true;
  }).windsurf;

in
{
  # 共通設定をインポート
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
  ];

  ############################
  # GUI 固有設定
  ############################

  # ブートローダ
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # WiFi設定
  networking.wireless.enable = true;
  networking.wireless.userControlled.enable = true;

  # フォント設定
  fonts = {
    packages = with pkgs; [
      # HackGen NF
      (pkgs.fetchzip {
        url = "https://github.com/yuru7/HackGen/releases/download/v2.9.0/HackGen_NF_v2.9.0.zip";
        hash = "sha256-Lh4WQJjeP4JuR8jSXpRNSrjRsNPmNXSx5AItNYMJL2A=";
      })
      noto-fonts-cjk-serif
      noto-fonts-cjk-sans
      noto-fonts-emoji
      nerd-fonts.jetbrains-mono
    ];

    fontDir.enable = true;

    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif CJK JP" "Noto Color Emoji" ];
        sansSerif = [ "Noto Sans CJK JP" "Noto Color Emoji" ];
        monospace = [ "HackGen Console NF" "JetBrainsMono Nerd Font" "Noto Color Emoji" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # X Server有効化
  services.xserver.enable = true;

  # LightDM Display Manager
  services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.gtk = {
      enable = true;
      theme.name = "Materia-dark";
      iconTheme.name = "Papirus-Dark";
      cursorTheme.name = "Breeze_Snow";
      extraConfig = ''
        background = /etc/nixos/assets/chirno_nix_desktop.png
        font-name = "Noto Sans Bold 11"
      '';
    };
  };

  # Hyprland有効化
  programs.hyprland.enable = true;

  # OBS Studio
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
    ];
  };

  # 1Password (allowUnfree is already set in flake.nix)
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = ["fixus" "agent"];
  };

  # Steam
  programs.steam.enable = true;

  # VirtualBox
  virtualisation.virtualbox.host.enable = true;

  # fixus ユーザー（Hyprland用）
  users.users.fixus = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "vboxusers"];
    packages = with pkgs; [
      firefox
      kitty
      waybar
    ];
    shell = pkgs.bash;
  };

  # fixusユーザーもNOPASSWD sudo可能に
  security.sudo.extraRules = [
    {
      users = ["fixus"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # Agent ユーザー定義
  users.users.agent = {
    isNormalUser = true;
    description = "Agent User";
    home = "/home/agent";
    extraGroups = [ "wheel" ];
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

  # GUI固有のシステムパッケージ
  environment.systemPackages = with pkgs; [
    # Hyprland関連
    waybar
    wl-clipboard
    hyprpaper
    wofi
    grim
    slurp
    swappy
    brightnessctl

    # GUI アプリケーション
    firefox
    kitty
    emacs-pgtk
    eog
    obsidian
    google-chrome
    vscode
    windsurf
    thunderbird

    # ツール
    steam-run
    sshfs
    rclone
    stow
    claude-code

    # 日本語入力
    fcitx5
    fcitx5-mozc
    fcitx5-gtk
    qt6.qtbase
  ];
}
