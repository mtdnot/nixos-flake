{ config, lib, pkgs, unstablePkgs, ... }:

{
  # ハードウェア設定を import
  imports = [
    ./hardware-configuration.nix
  ];

  # Nix コマンド / flake 有効化
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Unfree パッケージ許可
  nixpkgs.config.allowUnfree = true;

  # バイナリ互換 (glibc まわり)
  programs.nix-ld.enable = true;

  # ロケール・タイムゾーン
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "ja_JP.UTF-8";

  # IME 設定
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
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
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

  # sudo 設定
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

  # OBS Studio
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
    ];
  };

  # ブートローダ
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ネットワーク設定
  networking.wireless.enable = true;
  networking.wireless.userControlled.enable = true;
  networking.useDHCP = true;
  networking.networkmanager.enable = true;

  # wpa_supplicant 設定ファイル
  environment.etc."wpa_supplicant/ains-wifi.conf".text = ''
    network={
      ssid="ains-wifi"
      key_mgmt=WPA-EAP
      eap=PEAP
      identity="s1330019"
      password="agequodagis7010"
      phase2="auth=MSCHAPV2"
    }
  '';

  environment.etc."wpa_supplicant/aioi-wifi.conf".text = ''
    network={
      ssid="TP-Link_CCE4_5G"
      psk="84968579"
    }
  '';

  environment.etc."wpa_supplicant/licia-wifi.conf".text = ''
    network={
      ssid="licia-seminar2"
      psk="seminar11510"
    }
  '';

  environment.etc."wpa_supplicant/aquos-wifi.conf".text = ''
    network={
      ssid="AQUOS sense3"
      psk="12345678"
    }
  '';

  environment.etc."wpa_supplicant/jagura-wifi.conf".text = ''
    network={
      ssid="elecom-30fb2f"
      psk="2c3ahw8k4hyv"
    }
  '';

  environment.etc."wpa_supplicant/onyado-toho.conf".text = ''
    network={
      ssid="onyado-toho"
      psk="toho1960"
    }
  '';

  environment.etc."wpa_supplicant/home-wifi.conf".text = ''
    network={
      ssid="Buffalo-A-2E60"
      psk="aghg35fykvg6n"
    }
  '';

  # wpa_supplicant systemd サービス
  systemd.services.wpa_supplicant-ains-wifi = {
    description = "WPA Supplicant for ains-wifi";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      ExecStart = "/run/current-system/sw/sbin/wpa_supplicant -i wlp5s0 -c /etc/wpa_supplicant/ains-wifi.conf";
      Restart = "always";
    };
  };

  systemd.services.wpa_supplicant-home-wifi = {
    description = "WPA Supplicant for home-wifi";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      ExecStart = "/run/current-system/sw/sbin/wpa_supplicant -i wlp5s0 -c /etc/wpa_supplicant/home-wifi.conf";
      Restart = "always";
    };
  };

  systemd.services.wpa_supplicant-aquos-wifi = {
    description = "WPA Supplicant for aquos-wifi";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      ExecStart = "/run/current-system/sw/sbin/wpa_supplicant -i wlp5s0 -c /etc/wpa_supplicant/home-wifi.conf";
      Restart = "always";
    };
  };

  systemd.services.wpa_supplicant-licia-wifi = {
    description = "WPA Supplicant for licia-wifi";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      ExecStart = "/run/current-system/sw/sbin/wpa_supplicant -i wlp5s0 -c /etc/wpa_supplicant/licia-wifi.conf";
      Restart = "always";
    };
  };

  systemd.services.wpa_supplicant-jagura-wifi = {
    description = "WPA Supplicant for jagura-wifi";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      ExecStart = "/run/current-system/sw/sbin/wpa_supplicant -i wlp5s0 -c /etc/wpa_supplicant/jagura-wifi.conf";
      Restart = "always";
    };
  };

  systemd.services.wpa_supplicant-aioi-wifi = {
    description = "WPA Supplicant for aioi-wifi";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      ExecStart = "/run/current-system/sw/sbin/wpa_supplicant -i wlp5s0 -c /etc/wpa_supplicant/aioi-wifi.conf";
      Restart = "always";
    };
  };

  systemd.services.wpa_supplicant-onyado-toho = {
    description = "WPA Supplicant for onyado-toho";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      ExecStart = "/run/current-system/sw/sbin/wpa_supplicant -i wlp5s0 -c /etc/wpa_supplicant/onyado-toho-wifi.conf";
      Restart = "always";
    };
  };

  # ディスプレイマネージャー
  services.xserver.displayManager = {
    lightdm.enable = true;
  };

  services.xserver.displayManager.lightdm.greeters.gtk = {
    enable = true;
    theme.name = "Materia-dark";
    iconTheme.name = "Papirus-Dark";
    cursorTheme.name = "Breeze_Snow";
    extraConfig = ''
      background = /etc/nixos/assets/chirno_nix_desktop.png
      font-name = "Noto Sans Bold 11"
    '';
  };

  services.xserver.displayManager.lightdm.greeters.slick = {
    enable = false;
  };

  # VirtualBox
  virtualisation.virtualbox.host.enable = true;

  # 1Password
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password"
    "1password-gui"
  ];

  programs._1password.enable = true;

  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = ["fixus"];
  };

  # Hyprland
  programs.hyprland.enable = true;

  # X server 有効化
  services.xserver.enable = true;

  # ユーザー定義
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

  users.users.mtdnot = {
    isNormalUser = true;
    home = "/home/mtdnot";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
  };

  # システムパッケージ
  environment.systemPackages = with pkgs; [
    waybar
    wl-clipboard
    hyprpaper
    firefox
    kitty
    emacs-pgtk
    unzip
    git
    eog
    wofi
    pandoc
    libgcc
    brightnessctl
    nodejs
    zoxide
    grim
    slurp
    swappy
    htop
    glances
    gotop
    cmatrix
    neofetch
    tmux
    obsidian
    google-chrome
    vscode
    thunderbird
    steam-run
    sshfs
    rclone
    zsh
    gh
    mise
    stow
    claude-code
    fcitx5
    fcitx5-mozc
    fcitx5-gtk
    qt6.qtbase
  ] ++ [
    # unstablePkgs から windsurf を追加
    unstablePkgs.windsurf
  ];

  # Steam
  programs.steam.enable = true;

  system.stateVersion = "24.11";
}
