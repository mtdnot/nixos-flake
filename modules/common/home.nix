{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # 他のパッケージ
    claude-code
    tree
  ];

  programs.zsh.enable = true;
  programs.git.enable = true;

  home.stateVersion = "24.11";
}
