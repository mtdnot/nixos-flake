# bashでdirenvを使う

## 🔧 問題と解決

### 問題
bashでdirenvが動作しない：
```bash
[mtdnot@nixos:~]$ cd dev
# → 何も起きない（direnvが読み込まれない）
```

### 解決
`modules/common/home.nix` に以下を追加しました：

```nix
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
  enableZshIntegration = true;
  enableBashIntegration = true;  # ← これを追加！
};

programs.bash = {
  enable = true;
  # ... bash用の設定
};
```

## 🚀 適用方法

```bash
# 1. NixOS設定を更新
sudo nixos-rebuild switch --flake /home/mtdnot/nix#nixos-cui

# 2. bashを再起動
exec bash

# 3. direnvが動くか確認
cd ~/dev
# → direnv: loading ~/dev/.envrc
# → direnv: using flake /home/mtdnot/nix#agentshell
# ✅ 動いた！
```

## 📝 bashとzshの違い

### zshの場合
```zsh
[mtdnot@nixos ~]                                       14:55:00
$ cd dev
direnv: loading ~/dev/.envrc
direnv: using flake /home/mtdnot/nix#agentshell

(direnv) [mtdnot@nixos ~/dev]                          14:55:05
$
```

### bashの場合
```bash
[mtdnot@nixos ~]
$ cd dev
direnv: loading ~/dev/.envrc
direnv: using flake /home/mtdnot/nix#agentshell
direnv: export +AR +AS +CC ...

[mtdnot@nixos ~/dev]
$
```

## ✅ 動作確認

### テスト1: bashでdirenvが動くか
```bash
# bashを起動
exec bash

# devディレクトリに移動
cd ~/dev

# direnvのメッセージが表示されるはず
# direnv: loading ~/dev/.envrc
# direnv: using flake /home/mtdnot/nix#agentshell

# Node.jsが使えることを確認
which node
# → /nix/store/...-nodejs-20.x.x/bin/node

node --version
# → v20.x.x

# ✅ 成功！
```

### テスト2: 環境の自動切り替え
```bash
# ホームディレクトリ
cd ~
# direnv: unloading

# nixディレクトリ（PyTorch環境）
cd ~/nix
# direnv: loading ~/nix/.envrc
# direnv: using flake

python -c "import torch; print('PyTorch OK')"
# → PyTorch OK

# devディレクトリ（Node.js環境）
cd ~/dev
# direnv: unloading
# direnv: loading ~/dev/.envrc

node -e "console.log('Node.js OK')"
# → Node.js OK

# ✅ 自動切り替え成功！
```

## 🎨 bashプロンプトも改善

### Before
```bash
[mtdnot@nixos:~/dev]$
```

### After
```bash
[mtdnot@nixos ~/dev]
$
```

2行プロンプトで見やすくなります：
- 1行目: `[ユーザー@ホスト ディレクトリ]`
- 2行目: `$` プロンプト

## 🔄 zshとbashの切り替え

### zshを使う（推奨）
```bash
# zshに切り替え
exec zsh

# または起動時のデフォルトシェルを変更
chsh -s $(which zsh)
```

### bashを使う
```bash
# bashに切り替え
exec bash

# または起動時のデフォルトシェルを変更
chsh -s $(which bash)
```

## 🆚 zsh vs bash（どちらを使うべき？）

### zshの利点
- ✅ より強力な補完機能
- ✅ より柔軟なプロンプトカスタマイズ
- ✅ Nixコミュニティでより一般的
- ✅ home-managerの統合が優れている

### bashの利点
- ✅ より広く使われている（POSIX互換性）
- ✅ シンプル
- ✅ スクリプトの互換性が高い

### 推奨
**開発作業: zsh**
**スクリプト: bash**

両方使えるように設定済みなので、好みで選択できます。

## 📋 確認コマンド

```bash
# 現在のシェル確認
echo $SHELL

# direnvが有効か確認
direnv status

# 利用可能なシェル
cat /etc/shells

# zshのパス
which zsh

# bashのパス
which bash
```

## 🐛 トラブルシューティング

### 問題: bashでdirenvが動かない

**確認1: enableBashIntegrationが設定されているか**
```bash
grep -A 5 "programs.direnv" ~/nix/modules/common/home.nix
# → enableBashIntegration = true が含まれているはず
```

**確認2: 設定が適用されているか**
```bash
cat ~/.bashrc | grep direnv
# → eval "$(direnv hook bash)" が含まれているはず
```

**確認3: 手動でフックを追加（緊急時）**
```bash
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
source ~/.bashrc
```

### 問題: プロンプトが変わらない

```bash
# 設定を再適用
sudo nixos-rebuild switch --flake /home/mtdnot/nix#nixos-cui

# bashを再起動
exec bash

# .bashrcを確認
cat ~/.bashrc
```

### 問題: エイリアスが効かない

```bash
# エイリアス一覧を確認
alias

# 効いていない場合
source ~/.bashrc

# またはbashを再起動
exec bash
```

## ✨ 使えるエイリアス（bash/zsh共通）

```bash
# ファイル操作
ll          # ls -lah
la          # ls -A
..          # cd ..
...         # cd ../..

# NixOS操作
nrbs        # nixos-rebuild switch（自動でflake指定）
nrbt        # nixos-rebuild test
nrbs-nom    # 進捗表示版

# ツール
top         # btop
```

## 🎉 まとめ

- ✅ bashでもdirenvが動くように設定
- ✅ bashプロンプトも見やすく改善
- ✅ zshと同じエイリアスが使える
- ✅ 好きなシェルを選択可能

**適用方法:**
```bash
sudo nixos-rebuild switch --flake /home/mtdnot/nix#nixos-cui
exec bash  # または exec zsh
```

これで、bashでもzshでも快適な開発環境が使えます！
