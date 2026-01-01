{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # 開発ツール
    git
    gh                  # GitHub CLI
    lazygit            # Git TUI
    tig                # Git history viewer
    
    # エディタ
    vim
    neovim
    
    # ビルドツール
    gnumake
    cmake
    pkg-config
    
    # ランタイム
    # Note: nodejs is defined in home.nix to avoid version conflicts
    python3
    go
    rustc
    cargo

    # ユーティリティ
    tree
    htop
    btop               # Better htop
    ripgrep            # Better grep
    fd                 # Better find
    bat                # Better cat with syntax highlighting
    eza                # Better ls (exa successor)
    zoxide             # Smart cd
    fzf                # Fuzzy finder
    jq                 # JSON processor
    yq                 # YAML processor
    tldr               # Simplified man pages

    # ターミナル関連
    tmux               # Terminal multiplexer
    tmuxinator         # Tmux session manager
    tmuxp              # Tmux session manager (Python based)

    # ネットワーク
    curl
    wget
    httpie

    cloudflared        # Cloudflare Tunnel client

    # アーカイブ
    zip
    unzip
    p7zip

    # Docker/コンテナ
    docker
    docker-compose

    # プロジェクト環境管理
    direnv

  ]
  ++ lib.optional (pkgs ? claude-code) claude-code
  ++ lib.optional pkgs.stdenv.isDarwin mas;  # Mac App Store CLI (macOS only)
}
