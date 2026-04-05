{
  description = "Unified config for macOS / NixOS-gui / NixOS-cui";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    home-manager-unstable.url = "github:nix-community/home-manager/master";
    home-manager-unstable.inputs.nixpkgs.follows = "unstable";

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-openclaw.url = "github:openclaw/nix-openclaw";
    nix-openclaw.inputs.nixpkgs.follows = "unstable";
  };

  outputs = { self, nixpkgs, unstable, home-manager, home-manager-unstable, darwin, nix-openclaw, ... }:
  let
    lib = nixpkgs.lib;
    unstableLib = unstable.lib;

    # 任意の system 向け pkgs を取るヘルパ
    pkgsFor = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    # Linux (x86_64) 用の unstable パッケージセット
    unstablePkgs = import unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };

    # NixOS ホスト構成を作るヘルパ (stable 24.11)
    mkNixos = hostConfig: lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit unstablePkgs self nix-openclaw; };

      modules = [
        hostConfig
        { nixpkgs.overlays = [(final: prev: { claude-code = unstablePkgs.claude-code; })]; }
        home-manager.nixosModules.home-manager
        {
          nixpkgs.config.allowUnfree = true;

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.mtdnot = { imports = [ ./modules/common/home.nix ]; };
          home-manager.users.agent = { imports = [ ./modules/common/home.nix ]; };
          home-manager.users.anag = { imports = [ ./modules/users/anag/home.nix ]; };
          home-manager.users.rf = { imports = [ ./modules/users/rf/home.nix ]; };
          home-manager.users.zli = { imports = [ ./modules/users/zli/home.nix ]; };
          home-manager.users.natsu = { imports = [ ./modules/users/natsu/home.nix ]; };
        }
      ];
    };

    # NixOS ホスト構成を作るヘルパ (GUI + unstable base for OpenClaw)
    mkNixosWithAgentUnstable = hostConfig: unstableLib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit unstablePkgs self nix-openclaw; };

      modules = [
        hostConfig

        # nixpkgs設定とoverlays
        {
          nixpkgs.pkgs = import unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
            overlays = [ nix-openclaw.overlays.default ];
          };
        }

        home-manager-unstable.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.mtdnot = {
            imports = [ ./modules/common/home.nix ];
          };
        }
      ];
    };


  in {
    devShells.x86_64-linux.default = let pkgs = unstablePkgs; python = pkgs.python311; cc = pkgs.stdenv.cc.cc; in
      pkgs.mkShell {
        buildInputs = [ python python.pkgs.pip python.pkgs.setuptools python.pkgs.wheel python.pkgs.torch-bin pkgs.git pkgs.git-lfs cc ];
        shellHook = ''export LD_LIBRARY_PATH=${cc.lib}/lib:$LD_LIBRARY_PATH; export NPM_CONFIG_PREFIX=~/.local/npm-global; export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"'';
      };

    devShells.x86_64-linux.java21shell = let pkgs = unstablePkgs; in
      pkgs.mkShell { buildInputs = [ pkgs.jdk21 pkgs.maven pkgs.gradle pkgs.git pkgs.curl pkgs.jq ]; JAVA_HOME = "${pkgs.jdk21}"; };

    devShells.x86_64-linux.gptshell = let pkgs = unstablePkgs; in
      pkgs.mkShell {
        buildInputs = [ pkgs.playwright-driver.browsers pkgs.python312 pkgs.python312Packages.pip pkgs.python312Packages.setuptools pkgs.python312Packages.wheel pkgs.git pkgs.curl pkgs.wget pkgs.jq ];
        shellHook = ''export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}; export NPM_CONFIG_PREFIX=~/.local/npm-global; export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"'';
      };

    devShells.x86_64-linux.agentshell = let pkgs = unstablePkgs; python = pkgs.python312; in
      pkgs.mkShell {
        buildInputs = [ python python.pkgs.pip python.pkgs.setuptools python.pkgs.wheel python.pkgs.ipython python.pkgs.black python.pkgs.pytest python.pkgs.requests python.pkgs.virtualenv pkgs.nodejs_20 pkgs.openjdk17 pkgs.git pkgs.curl pkgs.jq ];
        shellHook = ''mkdir -p ~/.local/npm-global; export NPM_CONFIG_PREFIX=~/.local/npm-global; export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"'';
      };

    devShells.x86_64-linux.plantuml = let pkgs = unstablePkgs; in
      pkgs.mkShell {
        buildInputs = [ pkgs.plantuml pkgs.graphviz ];
      };

    ########################################
    ## Hosts
    ########################################
    nixosConfigurations.nixos-gui = mkNixos ./hosts/nixos-gui/configuration.nix;
    nixosConfigurations.nixos-agent = mkNixosWithAgentUnstable ./hosts/nixos-agent/configuration.nix;
    nixosConfigurations.nixos-cui = mkNixos ./hosts/nixos-cui/configuration.nix;

    darwinConfigurations.mac = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = { inherit unstablePkgs self; };
      modules = [
        ./hosts/mac/configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.mtdnot = { imports = [ ./modules/common/home.nix ]; };
          home-manager.users.agent = { imports = [ ./modules/common/home.nix ]; };
        }
      ];
    };
  };
}
