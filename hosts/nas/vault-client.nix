{ config, pkgs, lib, ... }:

{
  # Vault client configuration for secret retrieval
  environment.variables = {
    VAULT_ADDR = "https://vault.example.com:8200";  # Replace with actual Vault address
    VAULT_SKIP_VERIFY = "false";  # Set to true for self-signed certs in dev
  };

  # Create a systemd service for Vault token renewal
  systemd.services.vault-token-renew = {
    description = "Vault Token Renewal Service";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
      
      Environment = "VAULT_TOKEN_FILE=/run/vault/token";
      
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p /run/vault"
        "${pkgs.coreutils}/bin/chmod 700 /run/vault"
      ];
      
      # Authenticate with Vault using AppRole
      ExecStart = pkgs.writeShellScript "vault-auth" ''
        set -euo pipefail
        
        # Read AppRole credentials from secure location
        ROLE_ID=$(cat /etc/vault/role-id)
        SECRET_ID=$(cat /etc/vault/secret-id)
        
        # Authenticate and save token
        ${pkgs.vault-bin}/bin/vault write -format=json auth/approle/login \
          role_id="$ROLE_ID" \
          secret_id="$SECRET_ID" | \
          ${pkgs.jq}/bin/jq -r '.auth.client_token' > /run/vault/token
        
        chmod 600 /run/vault/token
      '';
      
      Restart = "on-failure";
      RestartSec = "5min";
    };
  };

  # Timer to renew token before expiry
  systemd.timers.vault-token-renew = {
    description = "Vault Token Renewal Timer";
    wantedBy = [ "timers.target" ];
    
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "4h";
      Persistent = true;
    };
  };

  # Helper script for services to get secrets from Vault
  environment.etc."vault/get-secret.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      set -euo pipefail
      
      SECRET_PATH="$1"
      FIELD="${2:-value}"
      
      if [ ! -f /run/vault/token ]; then
        echo "Error: Vault token not found. Is vault-token-renew service running?" >&2
        exit 1
      fi
      
      export VAULT_TOKEN=$(cat /run/vault/token)
      export VAULT_ADDR="${config.environment.variables.VAULT_ADDR}"
      
      ${pkgs.vault-bin}/bin/vault kv get -format=json "$SECRET_PATH" | \
        ${pkgs.jq}/bin/jq -r ".data.data.$FIELD"
    '';
  };

  # Create directories for Vault credentials
  systemd.tmpfiles.rules = [
    "d /etc/vault 0700 root root -"
    "d /run/vault 0700 root root -"
  ];
}
