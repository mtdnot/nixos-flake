{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ./dhcp-dns.nix 
    ./vault-client.nix
    ./cloudflared.nix
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

  # Add required packages
  environment.systemPackages = with pkgs; [
    vim
    git
    vault-bin
    cloudflared
    jq
    curl
  ];

  # Existing user configuration
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCtBVmY5TzSQKM1K8FdaLfXYYJ+yuxeQoKXLHCQMLP2NRwpSLH/uFPjJNGCxFXl8vL0RHbPrbX+EqgG6RcCPUIhkT63Y9JQ4xZV3iCCfIHRLGW1Ux+VQUk/VmP8zqNTuYzMsTJoB2xYO1yVqvMlOLRXEQKGI5VUGb8E2MJKhMXszB7+9RmxUkCflxsJkyE2OvFVJF3/b0/dMrL1mibxFf2DDzXCLPPGMRqE+8/RhNJKWwp1Cd4EizwPJlJaGdRKAqQOlbDN+z3M1vKGyMYBZE2Qvj1SxfIjMiEi0F+gCJBRqLrBCdQq4F3Y8ACzjJKQlBb0LTIvABtaC5YJK0vTd9cUQzP4SakCPxBANK2seyb7iW8VGRSG/fQCIJ7G6DfRYc1YKMmuJihQCKpJnTgdm9o9D6G8+P/Nt4/pQQBIvF2GGgxGGF2pbPDq3GVQZuGyeKzRvFqFHQzVnUOqVE+nGQQmvqQUdoCZBJtgUOPQ7YbNnOxUJ0jG2YWZ5u2IZGc="
    ];
  };

  users.users.mtdnot = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCtBVmY5TzSQKM1K8FdaLfXYYJ+yuxeQoKXLHCQMLP2NRwpSLH/uFPjJNGCxFXl8vL0RHbPrbX+EqgG6RcCPUIhkT63Y9JQ4xZV3iCCfIHRLGW1Ux+VQUk/VmP8zqNTuYzMsTJoB2xYO1yVqvMlOLRXEQKGI5VUGb8E2MJKhMXszB7+9RmxUkCflxsJkyE2OvFVJF3/b0/dMrL1mibxFf2DDzXCLPPGMRqE+8/RhNJKWwp1Cd4EizwPJlJaGdRKAqQOlbDN+z3M1vKGyMYBZE2Qvj1SxfIjMiEi0F+gCJBRqLrBCdQq4F3Y8ACzjJKQlBb0LTIvABtaC5YJK0vTd9cUQzP4SakCPxBANK2seyb7iW8VGRSG/fQCIJ7G6DfRYc1YKMmuJihQCKpJnTgdm9o9D6G8+P/Nt4/pQQBIvF2GGgxGGF2pbPDq3GVQZuGyeKzRvFqFHQzVnUOqVE+nGQQmvqQUdoCZBJtgUOPQ7YbNnOxUJ0jG2YWZ5u2IZGc="
    ];
  };

  users.groups.mtdnot = {};

  i18n = {
    defaultLocale = "ja_JP.UTF-8";
    supportedLocales = [ "ja_JP.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [ fcitx5-mozc fcitx5-gtk ];
    };
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  system.stateVersion = "24.11";
}
