# dotfiles統合モジュール
# 独立したdotfilesリポジトリを参照して設定を適用

{ config, lib, pkgs, ... }:

let
  # dotfilesリポジトリのパス
  # gitで管理している既存のdotfilesディレクトリを参照
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  # シンボリックリンクで各設定ファイルを配置
  home.file = {
    # Zsh設定（存在するファイルのみ）
    ".zprofile" = lib.mkIf (builtins.pathExists "${dotfilesPath}/zsh/.zprofile") {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/zsh/.zprofile";
    };
    
    # zshrcがない場合は作成することもできる
    # ".zshrc" = lib.mkIf (builtins.pathExists "${dotfilesPath}/zsh/.zshrc") {
    #   source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/zsh/.zshrc";
    # };
    
    # Tmux設定（存在チェック付き）
    # ".tmux.conf" = lib.mkIf (builtins.pathExists "${dotfilesPath}/tmux/.tmux.conf") {
    #   source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/tmux/.tmux.conf";
    # };
    
    # SSH設定（存在チェック付き）
    # ".ssh/config" = lib.mkIf (builtins.pathExists "${dotfilesPath}/ssh/config") {
    #   source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/ssh/config";
    # };
    
    # Emacs設定
    ".emacs.d" = lib.mkIf (builtins.pathExists "${dotfilesPath}/emacs") {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/emacs";
      recursive = true;
    };
  };

  # dotfilesセットアップスクリプト
  # Nix環境以外でも使えるようにする
  home.packages = with pkgs; [
    (writeScriptBin "dotfiles-setup" ''
      #!${pkgs.bash}/bin/bash
      
      DOTFILES_DIR="${dotfilesPath}"
      
      if [ ! -d "$DOTFILES_DIR" ]; then
        echo "Error: dotfiles directory not found at $DOTFILES_DIR"
        echo "Please clone your dotfiles repository first:"
        echo "  git clone <your-dotfiles-repo> $DOTFILES_DIR"
        exit 1
      fi
      
      echo "Dotfiles directory found at: $DOTFILES_DIR"
      echo "Symlinks are managed by Home Manager in Nix environment"
      echo ""
      echo "For non-Nix environments, run the setup script in your dotfiles repo:"
      echo "  cd $DOTFILES_DIR && ./setup.sh"
    '')
  ];
}