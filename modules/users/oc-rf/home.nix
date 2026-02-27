{ config, pkgs, ... }:
{
  imports = [ ../../common/home.nix ];
  home.username = "oc-rf";
  home.homeDirectory = "/home/oc-rf";
  home.stateVersion = "24.11";
}
