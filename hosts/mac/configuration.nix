{ config, pkgs, ... }:

{
  imports = [
    ./darwin-settings.nix
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  
  # Necessary for using flakes on this system.
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "mtdnot" ];
  };
  
  # Store optimization (macOS safe version)
  nix.optimise.automatic = true;

  # Garbage collection
  nix.gc = {
    automatic = true;
    interval = { Weekday = 7; };  # 毎週日曜日
    options = "--delete-older-than 30d";
  };

  # Set Git commit hash for darwin-version.
  programs.zsh.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  users.users.mtdnot = {
    name = "mtdnot";
    home = "/Users/mtdnot";
  };
  
  # Homebrew integration (既存のHomebrewと共存)
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };
    # 必要に応じてcasksやbrewsを追加
    casks = [
      # "visual-studio-code"
      # "firefox"
      # "slack"
    ];
  };
}