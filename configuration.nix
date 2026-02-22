# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
  # あなたがリンクしたコミットを含むnixpkgsのバージョンをインポート
  nixpkgs-windsurf = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/fe51d34885f7b5e3e7b59572796e1bcb427eccb1.tar.gz";
    # このコミットのハッシュ値を指定
    sha256 = "0pg3ibyagan1y57l1q1rwyrygrwg02p59p0fbgl23hf1nw58asda";
  };

  # インポートしたnixpkgsからパッケージを呼び出す
  windsurf = (import nixpkgs-windsurf {
    inherit (pkgs) system;
    config.allowUnfree = true; # Windsurfはunfreeライセンスのため必要
  }).windsurf;

in
{
  nixpkgs.config.allowUnfree = true;
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      #(import (builtins.fetchTarball "https://github.com/nix-community/nix-snapd/archive/main.tar.gz")).nixosModules.default            
    ];

  programs.nix-ld.enable = true;

# /etc/nixos/configuration.nix
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

  nix.settings.experimental-features = ["nix-command" "flakes"];

fonts = {
  packages = with pkgs; [
    # HackGen NF
    (pkgs.fetchzip {
      url = "https://github.com/yuru7/HackGen/releases/download/v2.9.0/HackGen_NF_v2.9.0.zip";
      hash = "sha256-Lh4WQJjeP4JuR8jSXpRNSrjRsNPmNXSx5AItNYMJL2A=";
    })
    # ほかのフォントを追加したい場合はここに
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


#  programs.emacs = {
#    enable = true;
#    package = pkgs.emacs-pgtk;
#};

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
    ];
  };


# boot snapd.socket and so on.

  #failed

  #services.snap.enable = true;

  #virtualisation.lxd.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #For using wpa_cli
  networking.wireless.enable = true;
  networking.wireless.userControlled.enable = true;


  networking.useDHCP = true;

  #wpa_supplicant conf file /nix management

  # WiFi configurations - passwords removed for security
  # environment.etc."wpa_supplicant/ains-wifi.conf".text=''
  #   network={
  #     ssid="ains-wifi"
  #     key_mgmt=WPA-EAP
  #     eap=PEAP
  #     identity="YOUR_IDENTITY"
  #     password="YOUR_PASSWORD"
  #     phase2="auth=MSCHAPV2"
  #   }
  # '';

  # environment.etc."wpa_supplicant/aioi-wifi.conf".text=''
  #   network={
  #     ssid="YOUR_SSID"
  #     psk="YOUR_PASSWORD"
  #   }
  # '';

    

  # boot as systemd service - WiFi services commented out for security

  # systemd.services.wpa_supplicant-example = {
  #   description = "WPA Supplicant for example";
  #   wantedBy = ["multi-user.target"];
  #   after = ["network.target"];
  #   serviceConfig = {
  #     ExecStart = "/run/current-system/sw/sbin/wpa_supplicant -i wlp5s0 -c /etc/wpa_supplicant/example.conf";
  #     Restart = "always";
  #   };
  # };


  #   services.displayManager.sddm.settings = {
  #     General = {
  #       # ←空文字にして Qt Virtual Keyboard を無効化
  #       InputMethod = "";
  #     };
  #   };


  services.xserver.displayManager = {
    lightdm.enable = true;
    # 他オプションがあればここに
  };
  
  services.xserver.displayManager.lightdm.greeters.gtk = {
    enable = true;
    theme.name = "Materia-dark";          # 落ち着いたダーク系GTK
    iconTheme.name = "Papirus-Dark";      # モダンな暗色アイコン
    cursorTheme.name = "Breeze_Snow";     # 白カーソル
#/etc/nixos/assets/anagi.png
    extraConfig = ''
      background = /etc/nixos/assets/chirno_nix_desktop.png
      font-name = "Noto Sans Bold 11"
      '';
  };
services.xserver.displayManager.lightdm.greeters.slick = {
   enable = false;
};
   virtualisation.virtualbox.host.enable = true;


   networking.networkmanager.enable = true;


  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password"
    "1password-gui"
  ];

  programs._1password.enable = true;

  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = ["fixus"];
  };



  programs.hyprland.enable = true;

  #services.wpa_supplicant.enable = true;
  #networking.hostName = "nixos"; # Define your hostname.
  #networking.networkmanager.enable = true;

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "ja_JP.UTF-8";

  # connection
  #networking.networkmanager.enable = true;
  #networking.wireless.enable = true;
  #networking.wireless.userControlled.enable = true;
  
  #for WPA
  #networking.wireless.environmentFile = "/etc/secrets.env";
  #services.wpa_supplicant.enable = true;  

  #desktop environment for xfce
 
  #X server and desktop
  services.xserver.enable = true;

  #user name
  users.users.fixus = {
  isNormalUser = true;
  extraGroups = ["wheel" "networkmanager" "vboxusers"];
  packages = with pkgs;[
    firefox
    kitty
    waybar
   ];
  shell = pkgs.bash;
  };
  
  #package
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
    windsurf
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
];

programs.steam.enable = true;


#for using sudo
#  security.sudo.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     tree
  #   ];
  # };

  # programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

}

