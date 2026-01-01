{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    
    matchBlocks = {
      "nixos-ssh.mtdnot.dev" = {
        hostname = "nixos-ssh.mtdnot.dev";
        proxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
      };
      
      "rpi" = {
        hostname = "rpi.mtdnot.dev";
        user = "mtdnot";
        identityFile = "~/Downloads/my-key.pem";
        serverAliveInterval = 15;
        serverAliveCountMax = 2;
      };
      
      "u-aizu" = {
        hostname = "std1dc33.u-aizu.ac.jp";
        user = "s1330019";
        serverAliveInterval = 15;
        serverAliveCountMax = 2;
      };
      
      "debian" = {
        hostname = "192.168.11.10";
        user = "mtdnot";
        identityFile = "~/Downloads/my-key.pem";
        proxyJump = "rpi";
        serverAliveInterval = 15;
        serverAliveCountMax = 2;
      };
      
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_gh";
        extraOptions = {
          AddKeysToAgent = "yes";
          UseKeychain = "yes";
        };
      };
    };
  };
}