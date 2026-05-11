{ config, lib, pkgs, ... }:

{
  systemd.services.openclaw-anag = {
    description = "OpenClaw - ANAG";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.nodejs_22 ];
    environment = { HOME = "/home/anag"; };
    serviceConfig = {
      Type = "simple";
      User = "anag";
      WorkingDirectory = "/home/anag";
      ExecStart = "/home/anag/.npm-global/bin/openclaw gateway run";
      Restart = "always";
      RestartSec = 5;
    };
  };

  systemd.services.openclaw-rf = {
    description = "OpenClaw - Refixa";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.nodejs_22 ];
    environment = { HOME = "/home/rf"; };
    serviceConfig = {
      Type = "simple";
      User = "rf";
      WorkingDirectory = "/home/rf";
      ExecStart = "/home/rf/.npm-global/bin/openclaw gateway run";
      Restart = "always";
      RestartSec = 5;
    };
  };

  systemd.services.openclaw-zli = {
    description = "OpenClaw - ZLI";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.nodejs_22 ];
    environment = { HOME = "/home/zli"; };
    serviceConfig = {
      Type = "simple";
      User = "zli";
      WorkingDirectory = "/home/zli";
      ExecStart = "/home/zli/.npm-global/bin/openclaw gateway run";
      Restart = "always";
      RestartSec = 5;
    };
  };

  systemd.services.openclaw-natsu = {
    description = "OpenClaw - natsu";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.nodejs_22 ];
    environment = { HOME = "/home/natsu"; };
    serviceConfig = {
      Type = "simple";
      User = "natsu";
      WorkingDirectory = "/home/natsu";
      ExecStart = "/home/natsu/.npm-global/bin/openclaw gateway run";
      Restart = "always";
      RestartSec = 5;
    };
  };
}
