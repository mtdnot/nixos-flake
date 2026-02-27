{ config, pkgs, ... }:
{
  imports = [ ../../common/home.nix ];
  home.username = "oc-anag";
  home.homeDirectory = "/home/oc-anag";
  home.stateVersion = "24.11";
}
