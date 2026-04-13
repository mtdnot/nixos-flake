{ config, pkgs, ... }:

{
  # Kea DHCP Server
  services.kea = {
    dhcp4 = {
      enable = true;
      settings = {
        interfaces-config = {
          interfaces = [ "ens18" ];
          dhcp-socket-type = "raw";
        };
        lease-database = {
          type = "memfile";
          persist = true;
          name = "/var/lib/kea/dhcp4.leases";
        };
        subnet4 = [
          {
            id = 1;
            subnet = "192.168.11.0/24";
            pools = [
              {
                pool = "192.168.11.103 - 192.168.11.200";
              }
            ];
            option-data = [
              {
                name = "routers";
                data = "192.168.11.1";
              }
              {
                name = "domain-name-servers";
                data = "192.168.11.12";
              }
              {
                name = "domain-name";
                data = "local.lan";
              }
            ];
            valid-lifetime = 86400;
            reservations = [
              {
                hw-address = "BC:24:11:EF:D7:96";
                ip-address = "192.168.11.10";
              }
              {
                hw-address = "2C:CF:67:28:79:6E";
                ip-address = "192.168.11.100";
              }
              {
                hw-address = "A8:A1:59:E5:C6:5E";
                ip-address = "192.168.11.101";
              }
              {
                hw-address = "A8:60:B6:13:0C:A0";
                ip-address = "192.168.11.102";
              }
            ];
          }
        ];
      };
    };
  };

  # DNS Server (dnsmasq)
  services.dnsmasq = {
    enable = true;
    settings = {
      local = "/local.lan/";
      domain = "local.lan";
      server = [ "8.8.8.8" "8.8.4.4" ];
      address = [
        "/nas.local.lan/192.168.11.12"
        "/router.local.lan/192.168.11.1"
        "/proxmox.local.lan/192.168.11.101"
      ];
      dhcp-leasefile = "/var/lib/kea/dhcp4.leases";
      cache-size = 1000;
      no-resolv = false;
    };
  };
  
  networking.firewall.allowedUDPPorts = [ 53 67 68 51820 ];
  networking.firewall.allowedTCPPorts = [ 53 ];
}
