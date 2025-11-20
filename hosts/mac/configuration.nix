darwinConfigurations.mac = darwin.lib.darwinSystem {
  system = "aarch64-darwin"; # or x86_64-darwin
  modules = [
    ./hosts/mac/configuration.nix

    home-manager.darwinModules.home-manager

    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;

      home-manager.users.mtdnot = {
        imports = [ ./modules/common/home.nix ];
      };
    }
  ];
};
