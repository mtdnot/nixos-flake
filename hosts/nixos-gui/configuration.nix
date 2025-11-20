{ config, pkgs, ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # 今は何も import しない。後で足す。
  # imports = [ ... ];

  system.stateVersion = "24.11";
}
