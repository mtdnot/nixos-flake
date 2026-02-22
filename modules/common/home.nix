{ config, pkgs, lib, ... }:

{
  imports = [
    ./zsh.nix
    ./packages.nix
    ./direnv.nix
    ../emacs      # Emacs設定モジュールをインポート
    ../lualatex   # LuaLaTeX環境モジュールをインポート
  ];

  # LuaLaTeX環境を有効化（最小構成）
  programs.lualatex = {
    enable = true;
    packageSet = "scheme-basic";  # 基本構成
    enableJapanese = true;         # 日本語文書サポート
    enableBibliography = false;    # 必要に応じて有効化
    enableDiagrams = false;        # 必要に応じて有効化
    enablePresentations = false;   # 必要に応じて有効化
    extraPackages = [
      # 必要に応じて追加: "amsmath" "graphics" "hyperref" など
    ];
  };

  home.packages = with pkgs; [
    # Node.js 22 (OpenClaw / npm global tools 用)
    nodejs_22
    tree
    # claude-code は npm global で管理 (npm i -g @anthropic-ai/claude-code)
    # emacsは専用モジュールで管理
    docker
    docker-compose
    cifs-utils

    # プロジェクト管理
    taskjuggler

    # 開発環境効率化ツール
    btop                    # 高機能システムモニター
    nix-output-monitor      # ビルド進捗可視化 (nom)

    # ネットワーク・開発ツール
    curl                    # HTTPクライアント、APIテスト
    wget                    # ファイルダウンロード
    gh                      # GitHub CLI (PR、Issue管理)
    jq                      # JSON処理ツール
    dnsutils                # DNS診断ツール (nslookup, dig, host)
    lsof

    # 画像処理ツール
    imagemagick             # convert, magick コマンド
    unzip
    inetutils  # FTPクライアント含む
    lftp
    openconnect
    # 論文
    quarto
    pandoc
  ];

  # npm グローバルバイナリへのパス（claude, openclaw等）
  home.sessionPath = [
    "$HOME/.local/npm-global/bin"
  ];

  # direnv: 自動環境アクティベーション
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;      # nix-direnv統合
    enableZshIntegration = true;   # zshとの統合
    enableBashIntegration = true;  # bashとの統合
  };

  # zsh設定: 見やすいプロンプト
  programs.zsh = {
    enable = true;

    # シンプルで見やすいプロンプト
    # 形式: [ユーザー@ホスト ディレクトリ]
    # $
    initExtra = ''
      # AWS プロファイル設定
      export AWS_PROFILE=sso

      # npm グローバルバイナリのパス追加
      export PATH="$(npm prefix -g 2>/dev/null)/bin:$PATH"

      # プロンプト設定
      autoload -U colors && colors

      # シンプルな2行プロンプト
      PROMPT='%F{green}[%n@%m %F{blue}%~%F{green}]%f
%F{cyan}$%f '

      # 右側プロンプト（時刻表示）
      RPROMPT='%F{yellow}%*%f'

      # direnv環境が読み込まれているときの表示
      if [ -n "$DIRENV_DIR" ]; then
        PROMPT='%F{magenta}(direnv)%f '$PROMPT
      fi
    '';

    # 便利なエイリアス
    shellAliases = {
      ll = "ls -lah";
      la = "ls -A";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";
      mas = "/home/mtdnot/dev/anag/mas/mas";
      # Nixコマンドのエイリアス
      nrb = "sudo nixos-rebuild";
      nrbs = "sudo nixos-rebuild switch --flake /home/mtdnot/nix#nixos-cui && echo 'Reloading shell configuration...' && exec $SHELL";
      nrbt = "sudo nixos-rebuild test --flake /home/mtdnot/nix#nixos-cui";

      # nom版
      nrb-nom = "sudo nom-rebuild";
      nrbs-nom = "sudo nom-rebuild switch --flake /home/mtdnot/nix#nixos-cui && echo 'Reloading shell configuration...' && exec $SHELL";

      # 便利なツール
      top = "btop";

      # Claude Code
      clauded = "claude --dangerously-skip-permissions";
    };

    # コマンド履歴設定
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
  };

  # bash設定: direnv対応とプロンプト
  programs.bash = {
    enable = true;

    # bashプロンプト設定
    initExtra = ''
      # AWS プロファイル設定
      export AWS_PROFILE=sso

      # npm グローバルバイナリのパス追加
      export PATH="$(npm prefix -g 2>/dev/null)/bin:$PATH"

      # カラフルなプロンプト
      PS1='\[\033[01;32m\][\u@\h \[\033[01;34m\]\w\[\033[01;32m\]]\[\033[00m\]\n\[\033[01;36m\]$\[\033[00m\] '
    '';

    # エイリアス（zshと同じ）
    shellAliases = {
      ll = "ls -lah";
      la = "ls -A";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";
      mas = "/home/mtdnot/dev/anag/mas/mas";
      # Nixコマンドのエイリアス
      nrb = "sudo nixos-rebuild";
      nrbs = "sudo nixos-rebuild switch --flake /home/mtdnot/nix#nixos-cui && echo 'Reloading shell configuration...' && exec $SHELL";
      nrbt = "sudo nixos-rebuild test --flake /home/mtdnot/nix#nixos-cui";

      # nom版
      nrb-nom = "sudo nom-rebuild";
      nrbs-nom = "sudo nom-rebuild switch --flake /home/mtdnot/nix#nixos-cui && echo 'Reloading shell configuration...' && exec $SHELL";

      # 便利なツール
      top = "btop";

      # Claude Code
      clauded = "claude --dangerously-skip-permissions";
    };

    # コマンド履歴設定
    historySize = 10000;
    historyFileSize = 20000;
  };

  programs.git = {
    enable = true;
    userName = "mtdnot";
    userEmail = "mtdnot1129@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "vim";
      color.ui = "auto";
    };

    aliases = {
      co = "checkout";
      br = "branch";
      ci = "commit";
      st = "status";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";
    };
  };

  home.stateVersion = "24.11";
}
