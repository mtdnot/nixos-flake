{ config, pkgs, lib, ... }:

# NAS 上の Vault サーバー（file backend）
#
# 初回のみ手動オペレーションが必要:
#   export VAULT_ADDR=http://192.168.11.12:8200
#   vault operator init        # unseal keys と root token を控える
#   vault operator unseal      # しきい値ぶん繰り返す
#
# 再起動後は sealed 状態になるため、手動で unseal するか auto-unseal を別途設定する。

{
  services.vault = {
    enable = true;
    package = pkgs.vault-bin;
    address = "192.168.11.12:8200";
    storageBackend = "file";
    storagePath = "/var/lib/vault";
    tlsCertFile = null;
    tlsKeyFile = null;
    extraConfig = ''
      api_addr = "http://192.168.11.12:8200"
      cluster_addr = "http://192.168.11.12:8201"
      ui = true
      disable_mlock = true
    '';
  };

  networking.firewall.allowedTCPPorts = [ 8200 8201 ];

  environment.systemPackages = [ pkgs.vault-bin ];

  environment.variables = {
    VAULT_ADDR = "http://192.168.11.12:8200";
  };
}
