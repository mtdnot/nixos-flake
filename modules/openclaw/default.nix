{ config, lib, pkgs, ... }:

{
  # systemdサービス: oc-anag
  systemd.services.openclaw-anag = {
    description = "OpenClaw - ANAG";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.nodejs_22 ];
    environment = {
      HOME = "/home/oc-anag";
    };
    serviceConfig = {
      Type = "simple";
      User = "oc-anag";
      WorkingDirectory = "/home/oc-anag";
      ExecStart = "/home/oc-anag/.npm-global/bin/openclaw gateway run";
      Restart = "always";
      RestartSec = 5;
    };
  };

  # systemdサービス: oc-rf
  systemd.services.openclaw-rf = {
    description = "OpenClaw - Refixa";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.nodejs_22 ];
    environment = {
      HOME = "/home/oc-rf";
    };
    serviceConfig = {
      Type = "simple";
      User = "oc-rf";
      WorkingDirectory = "/home/oc-rf";
      ExecStart = "/home/oc-rf/.npm-global/bin/openclaw gateway run";
      Restart = "always";
      RestartSec = 5;
    };
  };

  # systemdサービス: zli
  systemd.services.openclaw-zli = {
    description = "OpenClaw - ZLI";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.nodejs_22 ];
    environment = {
      HOME = "/home/zli";
    };
    serviceConfig = {
      Type = "simple";
      User = "zli";
      WorkingDirectory = "/home/zli";
      ExecStart = "/home/zli/.npm-global/bin/openclaw gateway run";
      Restart = "always";
      RestartSec = 5;
    };
  };
}
