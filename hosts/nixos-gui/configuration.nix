{ config, pkgs, ... }:

{
  imports = [
    ../../modules/virtual-display.nix
    ./hardware-configuration.nix
    ../../modules/openclaw
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  fileSystems."/mnt/samba" = {
    device = "//192.168.11.19/data";
    fsType = "cifs";
    options = [
      "credentials=/root/.smbcredentials"
      "uid=1000" "gid=100"
      "file_mode=0644" "dir_mode=0755"
      "x-systemd.automount" "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=10s" "x-systemd.mount-timeout=10s"
    ];
  };

  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "ja_JP.UTF-8";

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb = { layout = "jp"; variant = ""; };
  services.printing.enable = true;
  security.rtkit.enable = true;

  security.sudo.extraConfig = "Defaults:mtdnot !requiretty";
  security.sudo.extraRules = [
    { users = [ "mtdnot" ]; commands = [{ command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }]; }
    { users = [ "agent" ]; commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }]; }
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.mtdnot = {
    isNormalUser = true;
    description = "mtdnot";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ kdePackages.kate ];
  };

  users.users.agent = {
    isNormalUser = true;
    description = "AI agent operator";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
  };

  users.users.anag = {
    isNormalUser = true;
    description = "ANAG - 電離圏研究";
    extraGroups = [ "wheel" ];
  };

  users.users.rf = {
    isNormalUser = true;
    description = "Refixa - 自動化基盤";
    extraGroups = [ "wheel" ];
  };

  users.users.zli = {
    isNormalUser = true;
    description = "ZLI - サークル運営";
    extraGroups = [ "wheel" ];
  };

  programs.firefox.enable = true;
  programs.nix-ld.enable = true;
  virtualisation.docker.enable = true;
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [ cifs-utils chromium ];
  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 18791 18792 18793 ];

  users.users.natsu = {
    isNormalUser = true;
    description = "natsu - 日常・人を繋ぐ";
    extraGroups = [ "wheel" ];
  };

  system.stateVersion = "25.05";
}
