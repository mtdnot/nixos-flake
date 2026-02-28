{ config, pkgs, ... }:
{
  imports = [ ../../common/home.nix ];
  home.username = "rf";
  home.homeDirectory = "/home/rf";
  home.stateVersion = "24.11";
}
