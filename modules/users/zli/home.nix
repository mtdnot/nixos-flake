{ config, pkgs, ... }:
{
  imports = [ ../../common/home.nix ];
  home.username = "zli";
  home.homeDirectory = "/home/zli";
  home.stateVersion = "24.11";
}
