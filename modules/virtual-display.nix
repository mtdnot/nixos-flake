{ config, pkgs, lib, ... }:

let
  agentDisplays = {
    rf = { display = 99; vncPort = 5999; novncPort = 6099; };
    anag = { display = 98; vncPort = 5998; novncPort = 6098; };
    zli = { display = 97; vncPort = 5997; novncPort = 6097; };
    natsu = { display = 96; vncPort = 5996; novncPort = 6096; };
  };
  
  makeDisplayServices = user: cfg: {
    "virtual-display-${user}" = {
      description = "Virtual Display for ${user}";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      
      serviceConfig = {
        Type = "simple";
        User = user;
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        ExecStart = "${pkgs.xorg.xorgserver}/bin/Xvfb :${toString cfg.display} -screen 0 1920x1080x24";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
    
    "vnc-${user}" = {
      description = "VNC Server for ${user}";
      wantedBy = [ "multi-user.target" ];
      after = [ "virtual-display-${user}.service" ];
      requires = [ "virtual-display-${user}.service" ];
      
      serviceConfig = {
        Type = "simple";
        User = user;
        Environment = "DISPLAY=:${toString cfg.display}";
        ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display :${toString cfg.display} -forever -nopw -listen 0.0.0.0 -rfbport ${toString cfg.vncPort}";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
    
    "novnc-${user}" = {
      description = "noVNC Web Client for ${user}";
      wantedBy = [ "multi-user.target" ];
      after = [ "vnc-${user}.service" ];
      requires = [ "vnc-${user}.service" ];
      
      path = [ pkgs.procps pkgs.coreutils pkgs.nettools ];
      
      serviceConfig = {
        Type = "simple";
        User = user;
        ExecStart = "${pkgs.novnc}/bin/novnc --listen ${toString cfg.novncPort} --vnc localhost:${toString cfg.vncPort}";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
in
{
  environment.systemPackages = with pkgs; [
    x11vnc
    xorg.xorgserver
    novnc
    python3Packages.websockify
    procps
  ];
  
  networking.firewall.allowedTCPPorts = [ 
    5996 5997 5998 5999
    6096 6097 6098 6099
    9222
  ];
  
  systemd.services = lib.mkMerge (lib.mapAttrsToList makeDisplayServices agentDisplays);
}
