{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./dhcp-dns.nix
    ./vault.nix
    ./vault-autounseal.nix
    ./couchdb.nix
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-nas";
  nix.settings.trusted-users = [ "nixos" "root" "@wheel" ];
  networking.dhcpcd.enable = false;
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "192.168.11.12";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.11.1";
  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
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
      
      peers = [
        {
          # mac
          publicKey = "EyfI26iILGXQLh4izJs6vdrAHBzzAVDdFMdU1Jl3oQU=";
          allowedIPs = [ "10.0.0.2/32" ];
        }
      ];
    };
  };

  networking.nat = {
    enable = true;
    externalInterface = "ens18";
    internalInterfaces = [ "wg0" ];
  };

  networking.firewall.allowedUDPPorts = [ 51820 67 68 ];

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
    beets
    ffmpeg
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
    nodejs_20
  ];

  system.stateVersion = "24.11";


  # Kea DHCP Server

  # Kea DHCP Server / DNS は ./dhcp-dns.nix に集約

  # mtdnotユーザー（必要に応じて）
  users.users.mtdnot = {
    isNormalUser = true;
    group = "mtdnot";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDK/hi6f6Thm9H4exhlxZ6mGcyJ1Uo4ZT4GBlpfb2Eag5bnsuB2F+jVtdScZD5V2YkgWon06fPyzutphrVeNDcQjp1/tukEak1431nkDMVxbQCWoJh/KP87frwGoMKg6ElRNGlc8RWDMwQRHMGiWLyM2wIaN22usKDjwAv2yaZ0lBBpzUoKvYp+wlCco1e3YGsGgJC4MGols+goRIXgApa62SMUPnzdCrz2msU9KwqbCwHlL+bKbBs4AqAgcnbvqj8itpOOjIrV8GPRk3akHdqsu24UlVZBrE4Xb30MhTogCGTTwRbmj9/ul0hHkoeQjBB1zZ6O0xUqVVV5y5nxDpc3"
    ];
  };
  users.groups.mtdnot = {};

  # flake mkNixos の home-manager.users と対応させる（未定義だと HM が /var/empty と衝突）
  users.users.agent = {
    isNormalUser = true;
    home = "/home/agent";
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
  };
  users.users.anag = {
    isNormalUser = true;
    home = "/home/anag";
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
  };
  users.users.rf = {
    isNormalUser = true;
    home = "/home/rf";
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
  };
  users.users.zli = {
    isNormalUser = true;
    home = "/home/zli";
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
  };
  users.users.natsu = {
    isNormalUser = true;
    home = "/home/natsu";
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
  };
}
