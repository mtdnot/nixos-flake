{ config, pkgs, ... }:

{
  services.dnsmasq = {
    enable = true;
    settings = {
      # ローカルドメインのみ処理
      local = "/local.lan/";
      domain = "local.lan";
      
      # それ以外は上流DNSへ転送
      server = [
        "8.8.8.8"
        "8.8.4.4"
      ];
      
      # ローカルホスト定義
      address = [
        "/nas.local.lan/192.168.11.12"
        "/router.local.lan/192.168.11.1"
        "/proxmox.local.lan/192.168.11.101"
      ];
      
      # DHCPリースからホスト名を自動登録
      dhcp-leasefile = "/var/lib/kea/dhcp4.leases";
      
      # キャッシュ設定
      cache-size = 1000;
      
      # ローカル以外は転送を明示
      no-resolv = false;
    };
  };
  
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];
}
