{ pkgs, lib, ... }:

# CouchDB (Obsidian LiveSync 用)
#
# 管理者パスワードは起動時に Vault から取得し、/var/lib/couchdb/local.ini の
# [admins] セクションに平文で書き込む。CouchDB はこれを読むと自動で pbkdf2
# ハッシュ化してファイルを書き戻す。
#
# 初回セットアップ (NAS 上で 1 回だけ実行):
#
#   # 1. Vault に管理者パスワードを保存
#   export VAULT_ADDR=http://192.168.11.12:8200
#   export VAULT_TOKEN='<root token>'
#   vault kv put secret/couchdb admin='<決めたパスワード>'
#
#   # 2. CouchDB 専用の読み取り policy
#   vault policy write couchdb-ro - <<'EOF'
#   path "secret/data/couchdb" { capabilities = ["read"] }
#   EOF
#
#   # 3. AppRole 作成
#   vault write auth/approle/role/couchdb \
#     token_policies="couchdb-ro" \
#     token_ttl=1h token_max_ttl=4h \
#     secret_id_ttl=0 secret_id_num_uses=0
#
#   # 4. role_id / secret_id を NAS 上に配置
#   sudo install -d -m 0750 -o root -g couchdb /var/lib/couchdb-vault
#   vault read -field=role_id auth/approle/role/couchdb/role-id \
#     | sudo tee /var/lib/couchdb-vault/role_id >/dev/null
#   vault write -field=secret_id -f auth/approle/role/couchdb/secret-id \
#     | sudo tee /var/lib/couchdb-vault/secret_id >/dev/null
#   sudo chown root:couchdb /var/lib/couchdb-vault/{role_id,secret_id}
#   sudo chmod 0640 /var/lib/couchdb-vault/{role_id,secret_id}
#
#   # 5. 反映
#   sudo systemctl restart couchdb
#   journalctl -u couchdb -n 30 --no-pager
#
# パスワードを変更するには:
#   vault kv put secret/couchdb admin='<新パスワード>'
#   sudo systemctl restart couchdb

{
  services.couchdb = {
    enable = true;
    package = pkgs.couchdb3;
    adminUser = "admin";
    # placeholder: 起動時に preStart が Vault から取得した値で上書きする
    adminPass = "placeholder-overridden-by-vault-preStart";
    bindAddress = "0.0.0.0";
    port = 5984;

    extraConfig = ''
      [chttpd]
      max_http_request_size = 4294967296
      bind_address = 0.0.0.0
      port = 5984

      [couchdb]
      max_document_size = 50000000

      [httpd]
      enable_cors = true

      [cors]
      origins = app://obsidian.md,capacitor://localhost,http://localhost
      credentials = true
      methods = GET, PUT, POST, HEAD, DELETE
      headers = accept, authorization, content-type, origin, referer, x-csrf-token
    '';
  };

  # AppRole の role_id / secret_id を置く場所（root 作成・couchdb グループ読み取り）
  systemd.tmpfiles.rules = [
    "d /var/lib/couchdb-vault 0750 root couchdb -"
  ];

  systemd.services.couchdb = {
    after = [ "vault.service" "vault-auto-unseal.service" "network-online.target" ];
    wants = [ "vault.service" "vault-auto-unseal.service" ];
    path = [ pkgs.vault-bin pkgs.jq pkgs.gawk pkgs.coreutils ];
    environment.VAULT_ADDR = "http://192.168.11.12:8200";

    preStart = lib.mkAfter ''
      # Vault が unsealed になるのを最大 60 秒待つ
      for i in $(seq 1 30); do
        if vault status 2>/dev/null | grep -q 'Sealed *false'; then
          break
        fi
        sleep 2
      done

      if ! vault status 2>/dev/null | grep -q 'Sealed *false'; then
        echo "[couchdb-preStart] Vault not unsealed; keeping existing local.ini" >&2
        exit 0
      fi

      if [ ! -r /var/lib/couchdb-vault/role_id ] || [ ! -r /var/lib/couchdb-vault/secret_id ]; then
        echo "[couchdb-preStart] AppRole creds missing; keeping existing local.ini" >&2
        exit 0
      fi

      ROLE_ID=$(cat /var/lib/couchdb-vault/role_id)
      SECRET_ID=$(cat /var/lib/couchdb-vault/secret_id)

      TOKEN=$(vault write -format=json auth/approle/login \
        role_id="$ROLE_ID" secret_id="$SECRET_ID" \
        | jq -r '.auth.client_token')

      if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
        echo "[couchdb-preStart] AppRole login failed; keeping existing local.ini" >&2
        exit 0
      fi

      PASSWORD=$(VAULT_TOKEN="$TOKEN" vault kv get -field=admin secret/couchdb)

      if [ -z "$PASSWORD" ]; then
        echo "[couchdb-preStart] secret/couchdb admin field empty; keeping existing local.ini" >&2
        exit 0
      fi

      # local.ini の [admins] セクションだけ置換（他セクションは保持）
      LOCAL_INI=/var/lib/couchdb/local.ini
      TMP=$(mktemp)
      touch "$LOCAL_INI"

      awk '
        BEGIN { skip = 0 }
        /^\[admins\]/ { skip = 1; next }
        /^\[/        { skip = 0; print; next }
        !skip        { print }
      ' "$LOCAL_INI" > "$TMP"

      {
        echo "[admins]"
        echo "admin = $PASSWORD"
        echo ""
        cat "$TMP"
      } > "$LOCAL_INI"

      rm -f "$TMP"
      chmod 600 "$LOCAL_INI" || true

      echo "[couchdb-preStart] admin password injected from Vault"
    '';
  };

  networking.firewall.allowedTCPPorts = [ 5984 ];
}
