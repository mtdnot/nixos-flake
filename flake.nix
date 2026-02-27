{
  description = "Unified config for macOS / NixOS-gui / NixOS-cui";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, unstable, home-manager, darwin, ... }:
  let
    lib = nixpkgs.lib;

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

    # NixOS ホスト構成を作るヘルパ
    mkNixos = hostConfig: lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit unstablePkgs self; };

      modules = [
        hostConfig
        {
          nixpkgs.overlays = [
            (final: prev: {
              claude-code = unstablePkgs.claude-code;
            })
          ];
        }

        home-manager.nixosModules.home-manager
        {
          nixpkgs.config.allowUnfree = true;

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.mtdnot = {
            imports = [ ./modules/common/home.nix ];
          };

          home-manager.users.agent = {
            imports = [ ./modules/common/home.nix ];
          };

          # OpenClaw organization users
          home-manager.users.oc-anag = {
            imports = [ ./modules/users/oc-anag/home.nix ];
          };

          home-manager.users.oc-rf = {
            imports = [ ./modules/users/oc-rf/home.nix ];
          };
        }
      ];
    };

  in {
    ########################################
    ## 開発用 devShell (GPU / PyTorch 用・最小構成)
    ########################################
    devShells.x86_64-linux.default =
      let
        pkgs = unstablePkgs;
        python = pkgs.python311;
        cc = pkgs.stdenv.cc.cc;
      in
      pkgs.mkShell {
        buildInputs = [
          python
          python.pkgs.pip
          python.pkgs.setuptools
          python.pkgs.wheel

          # GPU 対応の PyTorch (cu128)
          python.pkgs.torch-bin

          # 開発ツール
          pkgs.git
          pkgs.git-lfs

          # C++ ランタイム
          cc
        ];

        shellHook = ''
          # C++ ランタイム
          export LD_LIBRARY_PATH=${cc.lib}/lib:$LD_LIBRARY_PATH

          # NixOS の NVIDIA ドライバを見せる
          if [ -d /run/opengl-driver/lib ]; then
            export LD_LIBRARY_PATH="/run/opengl-driver/lib:$LD_LIBRARY_PATH"
          fi
          if [ -d /run/opengl-driver-32/lib ]; then
            export LD_LIBRARY_PATH="/run/opengl-driver-32/lib:$LD_LIBRARY_PATH"
          fi

          # npm global を PATH の先頭に追加
          export NPM_CONFIG_PREFIX=~/.local/npm-global
          export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

          echo "=== devShell: torch-bin (CUDA 12.8 runtime) ==="
          echo "python -c 'import torch; print(torch.cuda.is_available(), torch.version.cuda, torch.__version__)'"
        '';
      };

    ########################################
    ## java21shell - Java 21 開発環境
    ########################################
    devShells.x86_64-linux.java21shell =
      let
        pkgs = unstablePkgs;
      in
      pkgs.mkShell {
        buildInputs = [
          pkgs.jdk21
          pkgs.maven
          pkgs.gradle
          pkgs.git
          pkgs.curl
          pkgs.jq
        ];

        shellHook = ''
          echo "=== Java 21 Development Shell ==="
          java --version
        '';
        
        JAVA_HOME = "${pkgs.jdk21}";
      };

    ########################################
    ## gptshell - GPT Factory development environment
    ########################################
    devShells.x86_64-linux.gptshell =
      let
        pkgs = unstablePkgs;
      in
      pkgs.mkShell {
        buildInputs = [
          pkgs.playwright-driver.browsers
          pkgs.python312
          pkgs.python312Packages.pip
          pkgs.python312Packages.setuptools
          pkgs.python312Packages.wheel
          pkgs.git
          pkgs.curl
          pkgs.wget
          pkgs.jq
        ];

        shellHook = ''
          echo "GPTShell environment activated!"
          export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
          export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
          export NPM_CONFIG_PREFIX=~/.local/npm-global
          export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
        '';
      };

    ########################################
    ## agentshell - @fission-ai/openspec 環境
    ########################################
    devShells.x86_64-linux.agentshell =
      let
        pkgs = unstablePkgs;
        python = pkgs.python312;
      in
      pkgs.mkShell {
        buildInputs = [
          python
          python.pkgs.pip
          python.pkgs.setuptools
          python.pkgs.wheel
          python.pkgs.ipython
          python.pkgs.black
          python.pkgs.pytest
          python.pkgs.requests
          python.pkgs.virtualenv
          pkgs.nodejs_20
          pkgs.openjdk17
          pkgs.git
          pkgs.curl
          pkgs.jq
        ];

        shellHook = ''
          echo "=== Agent Shell ==="
          mkdir -p ~/.local/npm-global
          export NPM_CONFIG_PREFIX=~/.local/npm-global
          export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
        '';
      };

    ########################################
    ## Hosts
    ########################################
    nixosConfigurations.nixos-gui = mkNixos ./hosts/nixos-gui/configuration.nix;
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

          home-manager.users.mtdnot = {
            imports = [ ./modules/common/home.nix ];
          };

          home-manager.users.agent = {
            imports = [ ./modules/common/home.nix ];
          };
        }
      ];
    };
  };
}
