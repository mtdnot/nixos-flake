{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    # Zinit plugin manager
    initExtraFirst = ''
      # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
    '';
    
    initExtra = ''
      # Zinit installer
      if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
        print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
        command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
        command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
          print -P "%F{33} %F{34}Installation successful.%f%b" || \
          print -P "%F{160} The clone has failed.%f%b"
      fi
      
      source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
      autoload -Uz _zinit
      (( ''${+_comps} )) && _comps[zinit]=_zinit
      
      # Powerlevel10k theme
      if [[ -f ~/tools/powerlevel10k/powerlevel10k.zsh-theme ]]; then
        source ~/tools/powerlevel10k/powerlevel10k.zsh-theme
      fi
      
      # P10k configuration
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      
      # Better history search
      bindkey '^R' history-incremental-search-backward
      bindkey '^P' up-history
      bindkey '^N' down-history
    '';
    
    history = {
      size = 10000;
      save = 10000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
    };
    
    shellAliases = {
      # Nix aliases
      rebuild = "darwin-rebuild switch --flake /private/etc/nix-darwin#mtdnotnoMacBook-Air --impure";
      
      # Claude alias
      clauded = "claude --dangerously-skip-permissions";
    };
    
    sessionVariables = {
      # Ruby gem path
      PATH = "$HOME/.gem/ruby/2.6.0/bin:$PATH";
      EDITOR = "vim";
    };
  };
}