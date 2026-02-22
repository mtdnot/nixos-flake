# direnv セットアップガイド

このドキュメントでは、direnvの初期設定と使い方を説明します。

## 📋 前提条件

1. `sudo nixos-rebuild switch --flake .#nixos-cui` で新しい設定を適用済み
2. 一度ログアウト・ログインしてzshの設定を再読み込み（またはシェルを再起動）

## 🚀 初回セットアップ

### 1. プロジェクトルート (`/home/mtdnot/nix`)

```bash
cd /home/mtdnot/nix

# 初回はブロックされる
# direnv: error /home/mtdnot/nix/.envrc is blocked. Run `direnv allow` to approve its content.

# 許可する
direnv allow

# 自動的にデフォルトのdevShellがアクティベートされる
# direnv: loading ~/nix/.envrc
# direnv: using flake
# === devShell: torch-bin (CUDA 12.8 runtime) ===
# python -c 'import torch; print(torch.cuda.is_available(), torch.version.cuda, torch.__version__)'
```

**このディレクトリで使える環境:**
- Python 3.11 + PyTorch (CUDA 12.8)
- Git, Git LFS
- C++ランタイム
- NVIDIA CUDAドライバー統合

### 2. 開発ディレクトリ (`~/dev`)

```bash
cd ~/dev

# 初回はブロックされる
# direnv: error /home/mtdnot/dev/.envrc is blocked. Run `direnv allow` to approve its content.

# 許可する
direnv allow

# agentshell環境がアクティベートされる
# direnv: loading ~/dev/.envrc
# direnv: using flake /home/mtdnot/nix#agentshell
# === Agent Shell - @fission-ai/openspec Environment ===
# Installing @fission-ai/openspec...
# Installing @openai/codex...
# ... etc
```

**このディレクトリで使える環境:**
- Node.js v20 LTS
- OpenJDK 17
- @fission-ai/openspec
- @openai/codex
- OpenAPI/Swaggerツール群
  - openapi-generator-cli
  - swagger-cli
  - redocly
  - spectral

## 📁 ディレクトリ構成と環境の対応

```
/home/mtdnot/
├── nix/                    # PyTorch/CUDA環境 (デフォルトdevShell)
│   ├── .envrc             # use flake
│   └── flake.nix
│
└── dev/                    # OpenSpec/Node.js環境 (agentshell)
    └── .envrc             # use flake /home/mtdnot/nix#agentshell
```

## 🔄 使い方

### 自動環境切り替え

ディレクトリを移動するだけで自動的に環境が切り替わります:

```bash
# ホームディレクトリ（通常環境）
cd ~
which python
# → /run/current-system/sw/bin/python (または見つからない)

# NixOS設定ディレクトリ（PyTorch環境）
cd ~/nix
which python
# → /nix/store/...-python3-3.11.6/bin/python
python -c "import torch; print(torch.__version__)"
# → 2.x.x+cu128

# 開発ディレクトリ（Node.js環境）
cd ~/dev
which node
# → /nix/store/...-nodejs-20.x.x/bin/node
which openspec
# → ~/.local/npm-global/bin/openspec

# ホームに戻る（環境がアンロード）
cd ~
which python
# → 元の環境に戻る
```

### 環境の確認

```bash
# 現在の環境を確認
direnv status

# どの.envrcが読み込まれているか
echo $DIRENV_DIR

# 環境変数を確認
env | grep -i nix
```

### 手動リロード

`.envrc` や `flake.nix` を変更した場合:

```bash
# 自動的に検出される
# direnv: error .envrc changed. Run `direnv allow` to reload.

direnv allow

# または強制リロード
direnv reload
```

## 🎯 実践例

### 例1: PyTorchプロジェクトでの作業

```bash
cd ~/nix

# 環境が自動アクティベート
# PyTorchが利用可能
python <<EOF
import torch
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA version: {torch.version.cuda}")
print(f"GPU count: {torch.cuda.device_count()}")
EOF
```

### 例2: OpenSpecプロジェクトでの作業

```bash
cd ~/dev

# agentshell環境が自動アクティベート
# OpenSpecコマンドが利用可能
openspec list
openspec validate --strict

# Node.jsツールも利用可能
npm --version
node --version
```

### 例3: プロジェクトごとに異なる環境

```bash
# プロジェクトAのディレクトリを作成
mkdir ~/dev/project-a
cd ~/dev/project-a

# 親ディレクトリの.envrcが自動的に適用される（agentshell）
# → Node.js環境で作業

# プロジェクトBで異なる環境が必要な場合
mkdir ~/project-b
cd ~/project-b
echo "use flake /home/mtdnot/nix" > .envrc
direnv allow

# → PyTorch環境で作業
```

## 🔧 カスタマイズ

### CUDA設定の追加 (~/nix/.envrc)

```bash
# .envrcの末尾に追加
export CUDA_VISIBLE_DEVICES=0
export CUDA_LAUNCH_BLOCKING=1
```

変更後:
```bash
direnv allow  # 再読み込み
```

### Node.js環境変数の追加 (~/dev/.envrc)

```bash
# .envrcの末尾に追加
export NODE_ENV=development
export DEBUG=*
```

変更後:
```bash
direnv allow  # 再読み込み
```

## 🐛 トラブルシューティング

### 問題1: direnvコマンドが見つからない

```bash
# 原因: NixOS設定が適用されていない
# 解決: システムを再ビルド
sudo nixos-rebuild switch --flake /home/mtdnot/nix#nixos-cui

# シェルを再起動
exec zsh
```

### 問題2: 環境がアクティベートされない

```bash
# direnvがzshに統合されているか確認
direnv status

# 出力例:
# direnv exec path /nix/store/...-direnv-2.35.0/bin/direnv
# DIRENV_CONFIG /home/mtdnot/.config/direnv
# bash_path /run/current-system/sw/bin/bash
# ...

# 統合されていない場合、シェルを再起動
exec zsh
```

### 問題3: 初回ロードが遅い

```bash
# 原因: nix-direnvが初回evaluationをキャッシュする
# 解決: 初回のみ時間がかかりますが、2回目以降は高速（0.1秒以下）

# 初回
cd ~/nix
# → 3-5秒かかる

cd ~ && cd ~/nix
# → 0.1秒以下で即座にアクティベート
```

### 問題4: flake.nixを変更したのに反映されない

```bash
# キャッシュをクリア
rm -rf .direnv

# 再度許可
direnv allow

# または強制的にキャッシュをクリアして再ビルド
nix-direnv-reload
```

### 問題5: エラーメッセージが表示される

```bash
# エラー内容を確認
direnv allow

# 詳細なログを確認
export DIRENV_LOG_FORMAT=  # ログを有効化
cd ~/nix
```

## 📚 高度な使い方

### サブディレクトリで異なる環境

```bash
# ~/devの下に特定プロジェクト用の環境
mkdir ~/dev/special-project
cd ~/dev/special-project

# このプロジェクトだけPython環境を使いたい
cat > .envrc << 'EOF'
# 親のagentshell環境を無効化
unset DIRENV_DIFF

# PyTorch環境を使用
use flake /home/mtdnot/nix
EOF

direnv allow
```

### 環境変数のオーバーライド

```bash
# プロジェクト固有の環境変数
cat >> ~/dev/my-project/.envrc << 'EOF'
# 親の.envrcを継承
source_up

# プロジェクト固有の設定
export API_KEY=your-key-here
export DATABASE_URL=postgresql://localhost/mydb
EOF

direnv allow
```

### レイアウト関数の使用

```bash
# より高度な設定
cat > .envrc << 'EOF'
use flake /home/mtdnot/nix#agentshell

# カスタムPATH追加
PATH_add ./bin
PATH_add ./scripts

# カスタム環境変数
export PROJECT_ROOT=$PWD
export LOG_LEVEL=debug
EOF

direnv allow
```

## ✅ チェックリスト

- [ ] `sudo nixos-rebuild switch --flake .#nixos-cui` で設定を適用
- [ ] シェルを再起動（`exec zsh`）
- [ ] `cd ~/nix && direnv allow` でプロジェクトルート環境を有効化
- [ ] `cd ~/dev && direnv allow` でagentshell環境を有効化
- [ ] `cd ~ && cd ~/nix` で自動アクティベートを確認
- [ ] `cd ~/dev` でagentshell環境への切り替えを確認
- [ ] Python環境で `python -c "import torch; print(torch.cuda.is_available())"` をテスト
- [ ] Node.js環境で `openspec --version` をテスト

## 🎉 完了！

これでディレクトリを移動するだけで自動的に適切な開発環境が利用できるようになりました！
