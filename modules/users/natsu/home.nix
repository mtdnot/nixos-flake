{ config, pkgs, ... }:
{
  imports = [ ../../common/home.nix ];
  home.username = "natsu";
  home.homeDirectory = "/home/natsu";
  home.stateVersion = "24.11";
}
