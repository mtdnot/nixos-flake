{ config, pkgs, ... }:
{
  imports = [ ../../common/home.nix ];
  home.username = "anag";
  home.homeDirectory = "/home/anag";
  home.stateVersion = "24.11";
}
