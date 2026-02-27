{ config, pkgs, ... }:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;  # Better Nix integration
    
    config = {
      global = {
        load_dotenv = true;  # .envファイルの自動読み込み
        strict_env = false;
      };
    };
  };
}