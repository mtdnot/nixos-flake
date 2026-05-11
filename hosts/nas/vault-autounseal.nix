{ pkgs, ... }:

# Vault auto-unseal (平文方式)
#
# /var/lib/vault-unseal/keys.txt に unseal key を threshold 個（通常 3）並べて置くと、
# 起動後に systemd oneshot が自動で unseal する。
#
# 初回セットアップ（NAS 上で root として 1 回だけ）:
#   install -d -m 0700 -o root -g root /var/lib/vault-unseal
#   cat > /var/lib/vault-unseal/keys.txt <<EOF
#   <unseal_key_1>
#   <unseal_key_2>
#   <unseal_key_3>
#   EOF
#   chmod 0600 /var/lib/vault-unseal/keys.txt
#
# 動作確認:
#   systemctl start vault-auto-unseal
#   systemctl status vault-auto-unseal
#   vault status

{
  systemd.tmpfiles.rules = [
    "d /var/lib/vault-unseal 0700 root root -"
  ];

  systemd.services.vault-auto-unseal = {
    description = "Auto-unseal Vault from plaintext keys file";
    wants = [ "vault.service" ];
    after = [ "vault.service" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    path = [ pkgs.vault-bin ];
    environment.VAULT_ADDR = "http://192.168.11.12:8200";

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };

    script = ''
      # Vault が API に応答するまで待つ（sealed=exit 2, unsealed=exit 0 どちらでも OK）
      for i in $(seq 1 30); do
        code=0
        vault status >/dev/null 2>&1 || code=$?
        if [ "$code" = 0 ] || [ "$code" = 2 ]; then
          break
        fi
        sleep 2
      done

      if ! vault status 2>/dev/null | grep -q 'Sealed *true'; then
        echo "already unsealed"
        exit 0
      fi

      if [ ! -f /var/lib/vault-unseal/keys.txt ]; then
        echo "no keys file; skipping" >&2
        exit 0
      fi

      while IFS= read -r key; do
        [ -z "$key" ] && continue
        vault operator unseal "$key" >/dev/null
        vault status 2>/dev/null | grep -q 'Sealed *false' && exit 0
      done < /var/lib/vault-unseal/keys.txt

      echo "ran out of keys, still sealed" >&2
      exit 1
    '';
  };
}
