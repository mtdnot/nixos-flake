{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.agent = { imports = [ ../../common/home.nix ]; };
  home-manager.users.anag = { imports = [ ../../users/anag/home.nix ]; };
  home-manager.users.rf = { imports = [ ../../users/rf/home.nix ]; };
  home-manager.users.zli = { imports = [ ../../users/zli/home.nix ]; };
  home-manager.users.natsu = { imports = [ ../../users/natsu/home.nix ]; };
}
