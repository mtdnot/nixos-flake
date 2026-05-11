{ config, pkgs, lib, ... }:

{
  # Cloudflare Tunnel service with Vault integration
  systemd.services.cloudflared-tunnel = {
    description = "Cloudflare Tunnel";
    after = [ "network-online.target" "vault-token-renew.service" ];
    wants = [ "network-online.target" ];
    requires = [ "vault-token-renew.service" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "notify";
      User = "cloudflared";
      Group = "cloudflared";
      
      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/lib/cloudflared" "/run/cloudflared" ];
      
      RuntimeDirectory = "cloudflared";
      RuntimeDirectoryMode = "0700";
      StateDirectory = "cloudflared";
      StateDirectoryMode = "0700";
      
      # Pre-start script to fetch credentials from Vault
      ExecStartPre = pkgs.writeShellScript "cloudflared-pre-start" ''
        set -euo pipefail
        
        echo "Fetching Cloudflare Tunnel credentials from Vault..."
        
        # Wait for Vault token
        for i in {1..30}; do
          if [ -f /run/vault/token ]; then
            break
          fi
          echo "Waiting for Vault token... ($i/30)"
          sleep 2
        done
        
        if [ ! -f /run/vault/token ]; then
          echo "Error: Vault token not available"
          exit 1
        fi
        
        # Fetch tunnel token from Vault
        export VAULT_TOKEN=$(cat /run/vault/token)
        export VAULT_ADDR="${config.environment.variables.VAULT_ADDR}"
        
        TUNNEL_TOKEN=$(${pkgs.vault-bin}/bin/vault kv get -format=json secret/cloudflare/tunnel | \
          ${pkgs.jq}/bin/jq -r '.data.data.token')
        
        # Write environment file
        cat > /run/cloudflared/env <<EOF
        TUNNEL_TOKEN=$TUNNEL_TOKEN
        EOF
        chmod 600 /run/cloudflared/env
        chown cloudflared:cloudflared /run/cloudflared/env
      '';
      
      EnvironmentFile = "-/run/cloudflared/env";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token \${TUNNEL_TOKEN}";
      
      Restart = "always";
      RestartSec = "5s";
      TimeoutStartSec = "30s";
    };
  };

  # Create cloudflared user and group
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
    home = "/var/lib/cloudflared";
    createHome = true;
  };
  
  users.groups.cloudflared = {};

  # Configuration template
  environment.etc."cloudflared/config.yml.template" = {
    mode = "0644";
    text = ''
      # Template config - actual values from Vault
      ingress:
        - hostname: nas.example.com
          service: http://localhost:80
        - hostname: ssh-nas.example.com
          service: ssh://localhost:22
        - service: http_status:404
      
      tunnel: <TUNNEL_ID_FROM_VAULT>
      credentials-file: /run/cloudflared/credentials.json
      
      loglevel: info
      metrics: localhost:2000
    '';
  };
}
