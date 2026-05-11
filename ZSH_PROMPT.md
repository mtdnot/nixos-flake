# zshプロンプト改善ガイド

## 🎨 新しいプロンプトのデザイン

### Before（見づらい）
```
nixos%
```

### After（見やすい）
```
[mtdnot@nixos ~/dev]                                    14:30:25
$
```

direnv環境が有効な場合:
```
(direnv) [mtdnot@nixos ~/nix]                          14:30:25
$
```

## 📋 変更内容

`modules/common/home.nix` に以下の設定を追加しました:

### 1. 2行プロンプト

**1行目**: `[ユーザー@ホスト カレントディレクトリ]` + 右端に時刻
**2行目**: `$` プロンプト

これにより:
- ✅ カレントディレクトリが一目でわかる
- ✅ コマンド入力位置が常に左端で統一
- ✅ 長いパスでもコマンドが見やすい
- ✅ direnv環境が有効かどうか一目でわかる

### 2. カラー

- **緑**: ブラケットとホスト名
- **青**: カレントディレクトリ
- **シアン**: `$` プロンプト
- **黄色**: 右端の時刻表示
- **マゼンタ**: direnv環境表示

### 3. 便利なエイリアス

以下のショートカットコマンドが使えるようになります:

#### ファイル操作
```bash
ll          # ls -lah (詳細表示、隠しファイル含む)
la          # ls -A (隠しファイル含む)
l           # ls -CF (カラム表示)
..          # cd ..
...         # cd ../..
```

#### NixOS操作
```bash
nrb         # sudo nixos-rebuild
nrbs        # sudo nixos-rebuild switch (自動でflake指定)
nrbt        # sudo nixos-rebuild test (自動でflake指定)

nrb-nom     # sudo nom-rebuild (進捗表示版)
nrbs-nom    # sudo nom-rebuild switch (進捗表示版)
```

#### ツール
```bash
top         # btop (高機能システムモニター)
```

## 🚀 適用方法

```bash
# システムに適用
sudo nixos-rebuild switch --flake /home/mtdnot/nix#nixos-cui

# または短縮版
nrbs

# ビルド進捗を見たい場合
nrbs-nom
```

適用後、シェルを再起動:
```bash
exec zsh
```

## 📝 実際の表示例

### 通常のディレクトリ
```
[mtdnot@nixos ~]                                       14:35:12
$ pwd
/home/mtdnot

[mtdnot@nixos ~]                                       14:35:15
$ cd nix

[mtdnot@nixos ~/nix]                                   14:35:18
$
```

### direnv環境が有効な場合
```
[mtdnot@nixos ~]                                       14:36:00
$ cd nix
direnv: loading ~/nix/.envrc
direnv: using flake
=== devShell: torch-bin (CUDA 12.8 runtime) ===

(direnv) [mtdnot@nixos ~/nix]                          14:36:05
$ python -c "import torch; print(torch.__version__)"
2.x.x+cu128

(direnv) [mtdnot@nixos ~/nix]                          14:36:10
$ cd ..
direnv: unloading

[mtdnot@nixos ~]                                       14:36:12
$
```

### エイリアスの使用例
```
[mtdnot@nixos ~/nix]                                   14:40:00
$ ll
total 48K
drwxr-xr-x  8 mtdnot users 4.0K 12月  8 14:00 .
drwxr-xr-x  5 mtdnot users 4.0K 12月  8 13:00 ..
-rw-r--r--  1 mtdnot users  234 12月  8 14:00 .envrc
drwxr-xr-x  8 mtdnot users 4.0K 12月  8 12:00 .git
-rw-r--r--  1 mtdnot users 8.2K 12月  8 14:00 flake.nix
...

[mtdnot@nixos ~/nix]                                   14:40:05
$ ..

[mtdnot@nixos ~]                                       14:40:06
$ nrbs
[sudo] mtdnot のパスワード:
building the system configuration...
...
```

## 🎨 カスタマイズ

### プロンプトの色を変更したい

`modules/common/home.nix` の `initExtra` セクションを編集:

```nix
initExtra = ''
  # プロンプト設定
  autoload -U colors && colors

  # カスタマイズ例: 青ベースのプロンプト
  PROMPT='%F{blue}[%n@%m %F{cyan}%~%F{blue}]%f
%F{green}$%f '

  # 右側プロンプト（時刻なしにしたい場合）
  # RPROMPT=''
'';
```

色の選択肢:
- `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`
- 数字でも指定可能: `%F{123}` (256色)

### 1行プロンプトに戻したい

```nix
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '
```

### Gitブランチを表示したい

```nix
initExtra = ''
  autoload -Uz vcs_info
  precmd_vcs_info() { vcs_info }
  precmd_functions+=( precmd_vcs_info )
  setopt prompt_subst
  zstyle ':vcs_info:git:*' formats '%F{yellow}(%b)%f'
  zstyle ':vcs_info:*' enable git

  PROMPT='%F{green}[%n@%m %F{blue}%~%f ''${vcs_info_msg_0_}%F{green}]%f
%F{cyan}$%f '
'';
```

表示例:
```
[mtdnot@nixos ~/nix (main)]                            14:50:00
$
```

### エイリアスを追加したい

`shellAliases` セクションに追加:

```nix
shellAliases = {
  # ... 既存のエイリアス ...

  # 自分用のエイリアス
  g = "git";
  gs = "git status";
  gp = "git pull";
  d = "docker";
  dc = "docker-compose";
};
```

## 🐛 トラブルシューティング

### プロンプトが変わらない

```bash
# 1. 設定を再適用
sudo nixos-rebuild switch --flake /home/mtdnot/nix#nixos-cui

# 2. シェルを再起動
exec zsh

# 3. それでも変わらない場合、home-manager設定を確認
home-manager generations
```

### 色が表示されない

```bash
# ターミナルが256色対応か確認
echo $TERM
# → xterm-256color や screen-256color が理想

# 色のテスト
for i in {0..255}; do
  printf "\x1b[38;5;${i}mcolour${i}\x1b[0m\n"
done
```

### エイリアスが効かない

```bash
# エイリアス一覧を確認
alias

# 特定のエイリアスを確認
which ll
# → ll: aliased to ls -lah

# 効いていない場合
source ~/.zshrc
```

## 📚 参考情報

### zshプロンプトのエスケープシーケンス

- `%n` - ユーザー名
- `%m` - ホスト名
- `%~` - カレントディレクトリ（ホームは`~`で表示）
- `%/` - カレントディレクトリ（フルパス）
- `%*` - 時刻 (HH:MM:SS)
- `%T` - 時刻 (HH:MM)
- `%D` - 日付 (YY-MM-DD)

### 色指定

- `%F{color}` - 前景色の開始
- `%f` - 色のリセット
- `%K{color}` - 背景色の開始
- `%k` - 背景色のリセット

### 便利なzshオプション

```bash
# コマンド履歴の共有
setopt share_history

# 重複履歴を削除
setopt hist_ignore_dups

# 自動補完
autoload -Uz compinit && compinit
```

これらは `initExtra` に追加できます。

## ✨ おすすめの追加カスタマイズ

### Oh My Zshやstarlightは使わない？

NixOSでは、home-managerで宣言的に管理する方が:
- ✅ 再現性が高い
- ✅ ロールバックが簡単
- ✅ シンプルで高速
- ✅ 依存関係が明確

必要な機能だけを `initExtra` に追加する方が推奨されます。

### より高機能なプロンプトが欲しい場合

Starlightなどのツールも使えます:

```nix
home.packages = with pkgs; [
  starship  # モダンなプロンプト
];

programs.zsh.initExtra = ''
  eval "$(starship init zsh)"
'';
```

ただし、今回の設定でも十分実用的です。
