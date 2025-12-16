{ config, pkgs, lib, ... }:

{
  imports = [
    ./zsh.nix
    ./packages.nix
    ./direnv.nix
  ];

  programs.git = {
    enable = true;
    userName = "mtdnot";
    userEmail = "mtdnot1129@gmail.com";
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "vim";
      color.ui = "auto";
    };
    
    aliases = {
      co = "checkout";
      br = "branch";
      ci = "commit";
      st = "status";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";
    };
  };

  home.stateVersion = "24.11";
}
