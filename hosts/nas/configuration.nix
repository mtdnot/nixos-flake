{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ./dhcp-dns.nix ];
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
      
      peers = [];
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

  # Open DHCP ports


  # Kea DHCP Server
  services.kea = {
    dhcp4 = {
      enable = true;
      settings = {
        interfaces-config = {
          interfaces = [ "ens18" ];
          dhcp-socket-type = "raw";
        };
        lease-database = {
          type = "memfile";
          persist = true;
          name = "/var/lib/kea/dhcp4.leases";
        };
        subnet4 = [
          {
            id = 1;
            subnet = "192.168.11.0/24";
            pools = [
              {
                pool = "192.168.11.103 - 192.168.11.200";  # 103から開始（100-102は予約用）
              }
            ];
            option-data = [
              {
                name = "routers";
                data = "192.168.11.1";
              }
              {
                name = "domain-name-servers";
                data = "192.168.11.12";  # 自身のDNSサーバーを使用
              }
              {
                name = "domain-name";
                data = "local.lan";
              }
            ];
            valid-lifetime = 86400;
            # 固定IP予約
            reservations = [
              {
                hw-address = "BC:24:11:EF:D7:96";
                ip-address = "192.168.11.10";
              }
              {
                hw-address = "2C:CF:67:28:79:6E";
                ip-address = "192.168.11.100";
              }
              {
                hw-address = "A8:A1:59:E5:C6:5E";
                ip-address = "192.168.11.101";
              }
              {
                hw-address = "A8:60:B6:13:0C:A0";
                ip-address = "192.168.11.102";
              }
            ];
          }
        ];
      };
    };
  };

}

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
