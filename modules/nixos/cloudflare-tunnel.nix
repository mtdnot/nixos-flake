{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.cloudflare-tunnel;
in
{
  options.services.cloudflare-tunnel = {
    enable = mkEnableOption "Cloudflare Tunnel for SSH access";

    tunnelName = mkOption {
      type = types.str;
      default = "nixos-ssh-tunnel";
      description = "Name of the Cloudflare tunnel";
    };

    tunnelCredentialsFile = mkOption {
      type = types.path;
      description = "Path to the tunnel credentials JSON file";
    };

    hostname = mkOption {
      type = types.str;
      example = "ssh.example.com";
      description = "Hostname for SSH access through Cloudflare";
    };
  };

  config = mkIf cfg.enable {
    # Cloudflare Tunnel systemd service
    systemd.services.cloudflared-tunnel = {
      description = "Cloudflare Tunnel for SSH";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "notify";
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run";
        Restart = "on-failure";
        RestartSec = "5s";

        # セキュリティ設定
        DynamicUser = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib/cloudflared" ];

        # 環境変数で設定ファイルのパスを指定
        Environment = [
          "TUNNEL_ORIGIN_CERT=/var/lib/cloudflared/cert.pem"
        ];
      };
    };

    # Cloudflare設定ファイル
    environment.etc."cloudflared/config.yml" = {
      text = ''
        tunnel: ${cfg.tunnelName}
        credentials-file: ${cfg.tunnelCredentialsFile}

        ingress:
          - hostname: ${cfg.hostname}
            service: ssh://localhost:22
          - service: http_status:404
      '';
      mode = "0644";
    };

    # ディレクトリ作成
    systemd.tmpfiles.rules = [
      "d /var/lib/cloudflared 0700 cloudflared cloudflared - -"
    ];
  };
}