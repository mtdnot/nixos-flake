{
  description = "Unified config for macOS / NixOS-gui / NixOS-cui";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-openclaw.url = "github:openclaw/nix-openclaw";
    nix-openclaw.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, unstable, home-manager, darwin, nix-openclaw, ... }:
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
      overlays = [ nix-openclaw.overlays.default ];
    };

    # NixOS ホスト構成を作るヘルパ (stable 24.11)
    mkNixos = hostConfig: lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit unstablePkgs self nix-openclaw; };

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
        }
      ];
    };

    # NixOS ホスト構成を作るヘルパ (unstable - GUI/OpenClaw用)
    mkNixosUnstable = hostConfig: lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit unstablePkgs self nix-openclaw; };

      modules = [
        hostConfig
        {
          # unstableをベースに使用
          nixpkgs.pkgs = unstablePkgs;
        }

        home-manager.nixosModules.home-manager
        {
          nixpkgs.config.allowUnfree = true;

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.mtdnot = {
            imports = [ ./modules/common/home.nix ];
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
          # Java 21
          pkgs.jdk21
          
          # ビルドツール
          pkgs.maven
          pkgs.gradle
          
          # 基本的な開発ツール
          pkgs.git
          pkgs.curl
          pkgs.jq
        ];

        shellHook = ''
          echo "=== Java 21 Development Shell ==="
          echo ""
          echo "Java version:"
          java --version
          echo ""
          echo "JAVA_HOME: $JAVA_HOME"
          echo ""
          echo "Available tools:"
          echo "  - java, javac (JDK 21)"
          echo "  - maven"
          echo "  - gradle"
          echo ""
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
          # Node.js環境
          pkgs.nodejs_20
          pkgs.playwright-driver.browsers
          
          # Python環境
          pkgs.python312
          pkgs.python312Packages.pip
          pkgs.python312Packages.setuptools
          pkgs.python312Packages.wheel
          
          # 基本的な開発ツール
          pkgs.git
          pkgs.curl
          pkgs.wget
          pkgs.jq
        ];

        shellHook = ''
          echo "🚀 GPTShell environment activated!"
          echo ""
          
          # Playwright環境変数の設定
          export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
          export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
          export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE="ubuntu-24.04"
          
          # npm globalの設定
          export NPM_CONFIG_PREFIX=~/.local/npm-global
          export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
          
          echo "=== Environment Info ==="
          echo "Node.js: $(node -v)"
          echo "Python: $(python --version)"
          echo "npm: $(npm -v)"
          echo ""
          echo "Playwright browsers available at: $PLAYWRIGHT_BROWSERS_PATH"
          echo ""
          echo "To enter this shell: nix develop ~/nix#gptshell"
          echo ""
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
          # Python環境
          python
          python.pkgs.pip
          python.pkgs.setuptools
          python.pkgs.wheel
          python.pkgs.ipython
          python.pkgs.black
          python.pkgs.pytest
          python.pkgs.requests
          python.pkgs.virtualenv

          # Node.js環境
          pkgs.nodejs_20  # Node.js v20 LTS

          # Java Runtime (openapi-generator-cli用)
          pkgs.openjdk17  # OpenJDK 17 LTS

          # 基本的な開発ツール
          pkgs.git
          pkgs.curl
          pkgs.jq
        ];

        shellHook = ''
          echo "=== Agent Shell - Python + OpenSpec Environment ==="
          echo ""

          # ローカルのnode_modulesディレクトリを作成（PATHの最優先に）
          mkdir -p ~/.local/npm-global
          export NPM_CONFIG_PREFIX=~/.local/npm-global
          # npm globalを最優先にするため、PATHの先頭に追加
          export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

          # @fission-ai/openspecがインストールされているか確認
          if ! command -v openspec &> /dev/null; then
            echo "Installing @fission-ai/openspec..."
            npm install -g @fission-ai/openspec@latest
          else
            echo "@fission-ai/openspec is already installed"
          fi

          # @openai/codexがインストールされているか確認
          if ! npm list -g @openai/codex &> /dev/null; then
            echo "Installing @openai/codex..."
            npm install -g @openai/codex@latest
          else
            echo "@openai/codex is already installed"
          fi

          # OpenAPI/Swagger関連ツールをインストール
          echo "Checking OpenAPI/Swagger tools..."

          # OpenAPI Generator CLI
          if ! command -v openapi-generator-cli &> /dev/null; then
            echo "Installing @openapitools/openapi-generator-cli..."
            npm install -g @openapitools/openapi-generator-cli@latest
          else
            echo "@openapitools/openapi-generator-cli is already installed"
          fi

          # Swagger CLI
          if ! command -v swagger-cli &> /dev/null; then
            echo "Installing @apidevtools/swagger-cli..."
            npm install -g @apidevtools/swagger-cli@latest
          else
            echo "@apidevtools/swagger-cli is already installed"
          fi

          # Redocly CLI
          if ! command -v redocly &> /dev/null; then
            echo "Installing @redocly/cli..."
            npm install -g @redocly/cli@latest
          else
            echo "@redocly/cli is already installed"
          fi

          # Spectral (OpenAPI linter)
          if ! command -v spectral &> /dev/null; then
            echo "Installing @stoplight/spectral-cli..."
            npm install -g @stoplight/spectral-cli@latest
          else
            echo "@stoplight/spectral-cli is already installed"
          fi

          # Spectralのデフォルト設定ファイルを作成
          if [ ! -f ~/.spectral.yaml ]; then
            echo "Creating default Spectral configuration..."
            cat > ~/.spectral.yaml << 'EOF'
extends: ["spectral:oas", "spectral:asyncapi"]
rules:
  operation-description: warn
  operation-operationId: error
  operation-tags: warn
  oas3-api-servers: warn
EOF
            echo "Default .spectral.yaml created at ~/.spectral.yaml"
          fi

          echo ""
          echo "=== Installed Tools ==="
          echo "Python: $(python --version)"
          echo "pip: $(pip --version)"
          echo "Node.js: $(node --version)"
          echo "npm: $(npm --version)"
          echo "Java: $(java --version | head -n 1)"
          echo ""
          echo "AI Tools:"
          echo "  - openspec (Fission AI)"
          echo "  - @openai/codex"
          echo ""
          echo "OpenAPI/Swagger Tools:"
          echo "  - openapi-generator-cli: Generate client/server code from OpenAPI specs"
          echo "  - swagger-cli: Validate and bundle OpenAPI/Swagger files"
          echo "  - redocly: Modern OpenAPI linting and documentation"
          echo "  - spectral: Flexible JSON/YAML linter for OpenAPI"
          echo ""
          echo "To enter this shell: nix develop .#agentshell"

          # 最後にPATHを再設定して npm global を最優先に
          export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
        '';
      };

    ########################################
    ## Hosts
    ########################################
    nixosConfigurations.nixos-gui = mkNixosUnstable ./hosts/nixos-gui/configuration.nix;
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
        }
      ];
    };
  };
}


