eval "$(/opt/homebrew/bin/brew shellenv)"
# .zprofile に書く（ログイン時1回だけ実行される）
if [[ -z $TMUX && $SHLVL -eq 1 ]]; then
  exec tmux
fi
