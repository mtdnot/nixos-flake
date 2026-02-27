{ config, lib, pkgs, ... }:

{
  # systemdサービス: oc-anag
  systemd.services.openclaw-anag = {
    description = "OpenClaw - ANAG";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      HOME = "/home/oc-anag";
      PATH = "/home/oc-anag/.npm-global/bin:${pkgs.nodejs_22}/bin:/run/current-system/sw/bin";
    };
    serviceConfig = {
      Type = "simple";
      User = "oc-anag";
      WorkingDirectory = "/home/oc-anag";
      ExecStart = "/home/oc-anag/.npm-global/bin/openclaw gateway start --foreground";
      Restart = "always";
      RestartSec = 5;
    };
  };

  # systemdサービス: oc-rf
  systemd.services.openclaw-rf = {
    description = "OpenClaw - Refixa";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      HOME = "/home/oc-rf";
      PATH = "/home/oc-rf/.npm-global/bin:${pkgs.nodejs_22}/bin:/run/current-system/sw/bin";
    };
    serviceConfig = {
      Type = "simple";
      User = "oc-rf";
      WorkingDirectory = "/home/oc-rf";
      ExecStart = "/home/oc-rf/.npm-global/bin/openclaw gateway start --foreground";
      Restart = "always";
      RestartSec = 5;
    };
  };
}
