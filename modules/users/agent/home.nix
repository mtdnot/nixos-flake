{ config, pkgs, lib, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "agent";
  home.homeDirectory = "/home/agent";

  # This value determines the Home Manager release that your
  # configuration is compatible with.
  home.stateVersion = "24.11";

  # Basic packages for agent user
  home.packages = with pkgs; [
    git
    vim
    curl
    wget
    jq
    tree
  ];

  # OpenClaw Configuration
  programs.openclaw = {
    enable = true;
    config = {
      gateway = {
        mode = "local";
        auth = {
          # TODO: Set your gateway token here or via environment variable
          # token = "your-gateway-token";
        };
      };
      channels.telegram = {
        # TODO: Create a Telegram bot via @BotFather and set the token file path
        # tokenFile = "/home/agent/.secrets/telegram-bot-token";

        # TODO: Get your Telegram user ID from @userinfobot and add it here
        # allowFrom = [ 123456789 ];
      };
    };
    # Add plugins here as needed
    # plugins = [
    #   { source = "github:openclaw/nix-steipete-tools?dir=tools/summarize"; }
    # ];
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "agent";
    userEmail = "agent@example.com";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "vim";
      color.ui = "auto";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
