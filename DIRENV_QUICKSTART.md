# direnv クイックスタートガイド

## 🎯 direnvとは？

**ディレクトリに入るだけで自動的に開発環境がアクティベートされるツール**

- ❌ もう `nix develop` を手動で実行する必要なし
- ✅ `cd` するだけで環境が切り替わる
- ✅ 2回目以降は0.1秒以下で超高速

## 📋 現在の状態確認

### Step 1: NixOS設定が適用されているか確認

```bash
# direnvコマンドが使えるか確認
which direnv
# → /nix/store/...-direnv-2.35.0/bin/direnv と表示されればOK

# nix-direnvが使えるか確認
which nix-direnv
# または
ls ~/.nix-profile/bin/nix-direnv
```

**表示されない場合:**
```bash
# まだNixOS設定を適用していない
sudo nixos-rebuild switch --flake /home/mtdnot/nix#nixos-cui

# ログアウト・ログインまたはシェル再起動
exec zsh
```

### Step 2: direnvがzshに統合されているか確認

```bash
# direnvのステータス確認
direnv status
```

**正常な出力例:**
```
direnv exec path /nix/store/...-direnv-2.35.0/bin/direnv
DIRENV_CONFIG /home/mtdnot/.config/direnv
bash_path /run/current-system/sw/bin/bash
disable_stdin false
warn_timeout 5s
whitelist.prefix []
whitelist.exact map[]
```

**エラーが出る場合:**
```bash
# zshの設定を再読み込み
source ~/.zshrc

# それでもダメなら再起動
exec zsh
```

## 🚀 direnvの使い方（完全ガイド）

### 基本的な流れ

```
1. ディレクトリに.envrcファイルを配置
2. そのディレクトリに入る
3. direnv allowで許可（初回のみ）
4. 以降、自動で環境がアクティベート！
```

## 📁 実践例

### 例1: プロジェクトルート（/home/mtdnot/nix）でPyTorch環境を使う

```bash
# 1. ディレクトリに移動
cd /home/mtdnot/nix

# 2. 初回はエラーメッセージが出る（これは正常）
# direnv: error /home/mtdnot/nix/.envrc is blocked. Run `direnv allow` to approve its content.

# 3. .envrcの内容を確認（安全確認）
cat .envrc
# use flake  ← これが書いてあればOK

# 4. 許可する（初回のみ）
direnv allow

# 5. 環境がアクティベートされる！
# 出力例:
# direnv: loading ~/nix/.envrc
# direnv: using flake
# direnv: nix-direnv: using cached dev shell
# === devShell: torch-bin (CUDA 12.8 runtime) ===
# python -c 'import torch; print(torch.cuda.is_available(), torch.version.cuda, torch.__version__)'

# 6. Pythonが使えることを確認
which python
# → /nix/store/...-python3-3.11.6/bin/python

python -c "import torch; print(torch.__version__)"
# → 2.x.x+cu128
```

**2回目以降:**
```bash
cd ~
cd /home/mtdnot/nix
# → 一瞬で環境がアクティベート（0.1秒以下）
```

### 例2: ~/devでagentshell環境を使う

```bash
# 1. ディレクトリに移動
cd ~/dev

# 2. 初回はブロックされる
# direnv: error /home/mtdnot/dev/.envrc is blocked. Run `direnv allow` to approve its content.

# 3. 内容を確認
cat .envrc
# use flake /home/mtdnot/nix#agentshell  ← これが書いてあればOK

# 4. 許可
direnv allow

# 5. agentshell環境がアクティベート！
# === Agent Shell - @fission-ai/openspec Environment ===
# Installing @fission-ai/openspec...
# ... (初回のみインストール処理)

# 6. Node.jsとopenspecが使えることを確認
which node
# → /nix/store/...-nodejs-20.x.x/bin/node

node --version
# → v20.x.x

openspec --version
# → 表示される
```

### 例3: 環境の切り替えを体験

```bash
# ホームディレクトリ（通常環境）
cd ~
which python
# → /run/current-system/sw/bin/python (または not found)

# nixディレクトリ（PyTorch環境）
cd ~/nix
# direnv: loading ~/nix/.envrc
# direnv: using flake
which python
# → /nix/store/...-python3-3.11.6/bin/python

python -c "import torch; print('PyTorch OK')"
# → PyTorch OK

# devディレクトリ（Node.js環境）
cd ~/dev
# direnv: unloading  ← 前の環境がアンロードされる
# direnv: loading ~/dev/.envrc
# direnv: using flake /home/mtdnot/nix#agentshell
which python
# → not found（Node.js環境にはPythonがない）

which node
# → /nix/store/...-nodejs-20.x.x/bin/node

# ホームに戻る
cd ~
# direnv: unloading
which node
# → not found（元の環境に戻る）
```

## 🔧 よくある操作

### .envrcを編集した場合

```bash
# .envrcを編集
vim ~/nix/.envrc

# direnvが自動検出してくれる
# direnv: error .envrc changed. Run `direnv allow` to reload.

# 再度許可
direnv allow

# 環境が再読み込みされる
```

### 手動でリロードしたい場合

```bash
# 強制的にリロード
direnv reload

# 完全にクリーンな状態から再ロード
rm -rf .direnv/  # キャッシュ削除
direnv allow
```

### 一時的にdirenvを無効にしたい

```bash
# 現在のシェルセッションでのみ無効化
direnv deny

# 再度有効化
direnv allow

# または環境変数で無効化
export DIRENV_LOG_FORMAT=""  # ログを抑制
```

### 特定のディレクトリでのみ無効化

```bash
cd ~/some-directory
# .envrcを削除またはリネーム
mv .envrc .envrc.disabled
```

## 📝 .envrcファイルの作り方

### パターン1: デフォルトのdevShellを使う

```bash
cd ~/my-project
echo "use flake /home/mtdnot/nix" > .envrc
direnv allow
```

### パターン2: agentshellを使う

```bash
cd ~/my-ai-project
echo "use flake /home/mtdnot/nix#agentshell" > .envrc
direnv allow
```

### パターン3: 環境変数も追加

```bash
cat > .envrc << 'EOF'
use flake /home/mtdnot/nix

# CUDA設定
export CUDA_VISIBLE_DEVICES=0
export CUDA_LAUNCH_BLOCKING=1

# Python設定
export PYTHONPATH=$PWD/src:$PYTHONPATH
EOF

direnv allow
```

### パターン4: プロジェクト独自のflakeを使う

```bash
# プロジェクト内にflake.nixがある場合
cd ~/my-project
echo "use flake" > .envrc
direnv allow
```

## 🎯 実践的なワークフロー

### ワークフロー1: 複数プロジェクトの管理

```bash
# プロジェクトごとに環境を分ける
~/projects/
├── ml-project/          # PyTorch環境
│   └── .envrc          # use flake /home/mtdnot/nix
├── api-project/         # Node.js環境
│   └── .envrc          # use flake /home/mtdnot/nix#agentshell
└── web-project/         # 別のNode.js環境
    └── .envrc          # use flake .  (プロジェクト独自のflake)

# プロジェクト間の移動で自動切り替え
cd ~/projects/ml-project
# → PyTorchが使える

cd ~/projects/api-project
# → Node.js + OpenSpecが使える

cd ~/projects/web-project
# → プロジェクト独自の環境
```

### ワークフロー2: サブディレクトリでの環境

```bash
# 親ディレクトリの.envrcが自動的に継承される
~/dev/
├── .envrc              # use flake /home/mtdnot/nix#agentshell
├── project-a/          # 自動的にagentshell
├── project-b/          # 自動的にagentshell
└── special/
    └── .envrc          # use flake /home/mtdnot/nix (独自の環境)

cd ~/dev/project-a
# → agentshell環境（親の.envrc）

cd ~/dev/special
# → PyTorch環境（自分の.envrc）
```

### ワークフロー3: GitHubからクローンしたプロジェクト

```bash
# 1. プロジェクトをクローン
cd ~/dev
git clone https://github.com/user/some-project
cd some-project

# 2. 必要な環境の.envrcを作成
echo "use flake /home/mtdnot/nix#agentshell" > .envrc
direnv allow

# 3. すぐに開発開始！
npm install
npm run dev
```

## 🔍 デバッグ・トラブルシューティング

### 問題: 環境がアクティベートされない

```bash
# 1. direnvのステータス確認
direnv status

# 2. .envrcの内容確認
cat .envrc

# 3. 手動で許可してみる
direnv allow

# 4. ログを有効にして確認
export DIRENV_LOG_FORMAT="%S %p %s"
cd /home/mtdnot/nix

# 5. エラーメッセージを確認
direnv allow 2>&1 | less
```

### 問題: "command not found: direnv"

```bash
# NixOS設定を適用
sudo nixos-rebuild switch --flake /home/mtdnot/nix#nixos-cui

# シェル再起動
exec zsh

# 確認
which direnv
```

### 問題: 初回ロードが遅い（3-5秒かかる）

```bash
# これは正常です！
# nix-direnvが初回にevaluationをキャッシュしています

# 2回目以降は超高速（0.1秒以下）
cd ~
cd /home/mtdnot/nix
# → ほぼ一瞬
```

### 問題: flake.nixを変更したのに反映されない

```bash
# キャッシュをクリア
rm -rf .direnv/

# 再度許可
direnv allow

# flakeのロックファイルを更新した場合
nix flake update
direnv reload
```

## 📊 direnvの状態確認コマンド

```bash
# 現在のdirenv状態
direnv status

# 読み込まれている環境変数
direnv export zsh | less

# 現在アクティブな.envrcのパス
echo $DIRENV_DIR

# キャッシュの場所
ls -la .direnv/

# ログの有効化
export DIRENV_LOG_FORMAT="%S %p %s"
```

## 🎓 高度な使い方

### 複数のflakeを組み合わせる

```bash
cat > .envrc << 'EOF'
# Python環境
use flake /home/mtdnot/nix

# Node.jsツールも追加で使いたい
eval "$(nix print-dev-env /home/mtdnot/nix#agentshell)"
EOF
```

### プロジェクト固有の設定を追加

```bash
cat > .envrc << 'EOF'
# ベース環境
use flake /home/mtdnot/nix#agentshell

# プロジェクト固有のPATH
PATH_add ./bin
PATH_add ./scripts

# 環境変数
export PROJECT_ROOT=$PWD
export LOG_LEVEL=debug
export DATABASE_URL=postgresql://localhost/mydb
EOF

direnv allow
```

### レイアウト関数の活用

```bash
cat > .envrc << 'EOF'
# レイアウト: Python仮想環境
layout python3

# Nixパッケージも使う
use flake /home/mtdnot/nix
EOF
```

## ✅ チェックリスト

確認してください:

- [ ] `which direnv` でdirenvコマンドが見つかる
- [ ] `direnv status` でステータスが表示される
- [ ] `/home/mtdnot/nix/.envrc` が存在する
- [ ] `~/dev/.envrc` が存在する
- [ ] `cd /home/mtdnot/nix` で環境がアクティベートされる
- [ ] `cd ~/dev` でagentshell環境がアクティベートされる
- [ ] `cd ~` で環境がアンロードされる

すべて✅なら完璧です！

## 🎉 まとめ

**direnvを使う3ステップ:**

1. `.envrc` をディレクトリに配置
2. `direnv allow` で許可（初回のみ）
3. あとは `cd` するだけ！

**もう `exec zsh` は不要です！**

ディレクトリを移動するだけで自動的に環境が切り替わります。
