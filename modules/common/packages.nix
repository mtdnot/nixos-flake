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
    nodejs_20
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
    
    # ネットワーク
    curl
    wget
    httpie
    
    # アーカイブ
    zip
    unzip
    p7zip
    
    # Docker/コンテナ
    docker
    docker-compose
    
    # プロジェクト環境管理
    direnv
    
    # macOS specific
    mas                # Mac App Store CLI
    
  ] ++ lib.optional (pkgs ? claude-code) claude-code;
}