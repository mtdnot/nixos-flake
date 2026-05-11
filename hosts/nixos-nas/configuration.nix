{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-nas";
  time.timeZone = "Asia/Tokyo";

  services.openssh.enable = true;

  # パスワードなしsudo
  security.sudo.wheelNeedsPassword = false;

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "samba" "jellyfin" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDK/hi6f6Thm9H4exhlxZ6mGcyJ1Uo4ZT4GBlpfb2Eag5bnsuB2F+jVtdScZD5V2YkgWon06fPyzutphrVeNDcQjp1/tukEak1431nkDMVxbQCWoJh/KP87frwGoMKg6ElRNGlc8RWDMwQRHMGiWLyM2wIaN22usKDjwAv2yaZ0lBBpzUoKvYp+wlCco1e3YGsGgJC4MGols+goRIXgApa62SMUPnzdCrz2msU9KwqbCwHlL+bKbBs4AqAgcnbvqj8itpOOjIrV8GPRk3akHdqsu24UlVZBrE4Xb30MhTogCGTTwRbmj9/ul0hHkoeQjBB1zZ6O0xUqVVV5y5nxDpc3"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/nas 0755 nixos users - -"
    "d /srv/nas/music 0755 nixos users - -"
    "d /srv/nas/videos 0755 nixos users - -"
    "d /srv/nas/images 0755 nixos users - -"
    "d /srv/nas/public 0755 nixos users - -"
  ];

  # WireGuard VPN
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.0.0.1/24" ];
      listenPort = 51820;
      privateKeyFile = "/var/lib/wireguard/private.key";

      peers = [];
    };
  };

  networking.nat = {
    enable = true;
    externalInterface = "ens18";
    internalInterfaces = [ "wg0" ];
  };

  networking.firewall.allowedUDPPorts = [ 51820 ];

  # Samba
  services.samba = {
    enable = true;
    openFirewall = true;
    package = pkgs.samba4Full;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "nixos-nas";
        "netbios name" = "nixos-nas";
        "security" = "user";
        "map to guest" = "bad user";
      };

      music = {
        "path" = "/srv/nas/music";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "nixos";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      videos = {
        "path" = "/srv/nas/videos";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "nixos";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      images = {
        "path" = "/srv/nas/images";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "nixos";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      public = {
        "path" = "/srv/nas/public";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.avahi = {
    enable = true;
    openFirewall = true;
    publish.enable = true;
    publish.userServices = true;
    nssmdns4 = true;
  };

  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = "/srv/nas/music";
      DataFolder = "/var/lib/navidrome";
      Address = "0.0.0.0";
      Port = 4533;
      EnableSharing = false;
    };
  };

  systemd.services.navidrome.serviceConfig = {
    BindReadOnlyPaths = [ "/srv/nas/music" ];
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "nixos";
  };

  networking.firewall.enable = true;

  environment.systemPackages = with pkgs; [
    tmux
    htop
    iotop
    vim
    git
    wget
    curl
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    wireguard-tools
  ];

  system.stateVersion = "24.11";
}
