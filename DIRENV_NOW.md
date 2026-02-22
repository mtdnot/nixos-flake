# 今すぐdirenvを使う（5分ガイド）

## ⚡ 超簡単3ステップ

### Step 1: NixOS設定を適用（1分）

```bash
# システムに新しい設定を適用
sudo nixos-rebuild switch --flake /home/mtdnot/nix#nixos-cui
```

パスワードを入力して待つだけ。

### Step 2: シェルを再起動（10秒）

```bash
# 新しいシェルを起動（これで設定が有効になる）
exec zsh
```

### Step 3: direnvを許可して使う（1分）

```bash
# プロジェクトルートに移動
cd /home/mtdnot/nix

# エラーが出る（正常）
# direnv: error .envrc is blocked. Run `direnv allow` to approve its content.

# 許可する
direnv allow

# ✅ 完了！環境がアクティベートされた！
# direnv: loading ~/nix/.envrc
# direnv: using flake
# === devShell: torch-bin (CUDA 12.8 runtime) ===
```

これだけです！

---

## 🧪 動作テスト

### テスト1: PyTorch環境の確認

```bash
# /home/mtdnot/nixにいることを確認
pwd
# → /home/mtdnot/nix

# Pythonが使える
python -c "import torch; print(torch.__version__)"
# → 2.x.x+cu128 と表示されればOK！
```

### テスト2: 自動切り替えの確認

```bash
# 一度ホームに戻る
cd ~
# direnv: unloading ← 環境がアンロード

# もう一度nixディレクトリへ
cd /home/mtdnot/nix
# direnv: loading ~/nix/.envrc ← 自動でアクティベート！
# → 今度は一瞬（0.1秒以下）

# ✅ 成功！もう手動で nix develop する必要なし！
```

### テスト3: agentshell環境の確認

```bash
# devディレクトリに移動
cd ~/dev

# 初回は許可が必要
direnv allow

# Node.js環境がアクティベート
node --version
# → v20.x.x

openspec --version
# → 表示される

# ✅ 成功！
```

### テスト4: 環境の自動切り替え

```bash
# PyTorch環境
cd ~/nix
python -c "print('PyTorch環境')"
# → PyTorch環境

# Node.js環境
cd ~/dev
node -e "console.log('Node.js環境')"
# → Node.js環境

# 元に戻る
cd ~
# → どちらの環境もアンロード

# ✅ 成功！ディレクトリ移動だけで環境が切り替わる！
```

---

## 🎯 日常的な使い方

### 毎日の作業フロー

```bash
# 朝、作業を開始
cd ~/nix
# → 自動でPyTorch環境

# コーディング...
vim train.py
python train.py

# OpenSpecの作業に切り替え
cd ~/dev
# → 自動でagentshell環境

# OpenSpecコマンド実行
openspec list
openspec validate --strict

# 終わり！環境切り替えは全部自動！
```

### 新しいプロジェクトを始める

```bash
# 新しいディレクトリを作成
mkdir ~/dev/new-project
cd ~/dev/new-project

# 親ディレクトリの環境が自動継承される
# → agentshell環境が使える！

# または、プロジェクト専用の環境が欲しい場合
echo "use flake /home/mtdnot/nix" > .envrc
direnv allow
# → PyTorch環境に切り替わる
```

---

## 🔧 よくある質問

### Q1: `exec zsh` は毎回必要？

**A: いいえ！**

`exec zsh` が必要なのは：
- ✅ NixOS設定を適用した直後（最初の1回だけ）
- ✅ home.nixを変更してシステムを更新した後

普段の使用では不要です。`cd` するだけで環境が切り替わります。

### Q2: ディレクトリに入っても何も起きない

**A: 2つの原因が考えられます**

**原因1: まだ許可していない**
```bash
cd /home/mtdnot/nix
# エラーメッセージを確認
# → "Run `direnv allow`" と出たら：
direnv allow
```

**原因2: .envrcファイルがない**
```bash
ls -la .envrc
# → ファイルが存在するか確認

# なければ作成
echo "use flake" > .envrc
direnv allow
```

### Q3: エラーが出る

**エラー1: "command not found: direnv"**
```bash
# → まだNixOS設定を適用していない
sudo nixos-rebuild switch --flake /home/mtdnot/nix#nixos-cui
exec zsh
```

**エラー2: ".envrc is blocked"**
```bash
# → これは正常！セキュリティ機能
# 内容を確認してから許可する
cat .envrc
direnv allow
```

**エラー3: "error: getting status of '/nix/store/...': No such file or directory"**
```bash
# → キャッシュの問題
rm -rf .direnv/
direnv allow
```

### Q4: 初回が遅い（3-5秒）

**A: これは正常です！**

初回だけnix-direnvがevaluationをキャッシュします。
2回目以降は0.1秒以下で超高速になります。

```bash
# 初回
cd ~/nix
# → 3-5秒 (初回のみ)

# 2回目以降
cd ~ && cd ~/nix
# → 0.1秒以下 (超高速！)
```

---

## 📋 トラブルシューティング用コマンド

```bash
# 1. direnvがインストールされているか
which direnv

# 2. direnvのステータス
direnv status

# 3. .envrcの内容確認
cat .envrc

# 4. 現在読み込まれている環境
echo $DIRENV_DIR

# 5. キャッシュの状態
ls -la .direnv/

# 6. 強制リロード
direnv reload

# 7. キャッシュクリア
rm -rf .direnv/
direnv allow
```

---

## ✅ 成功の確認

以下をすべて試して、全部成功すればOK：

```bash
# 1. ホームディレクトリ
cd ~
which python
# → システムのpython または not found

# 2. nixディレクトリ
cd /home/mtdnot/nix
which python
# → /nix/store/...-python3-3.11.6/bin/python

python -c "import torch; print('OK')"
# → OK

# 3. devディレクトリ
cd ~/dev
which node
# → /nix/store/...-nodejs-20.x.x/bin/node

node --version
# → v20.x.x

# 4. 自動切り替え
cd ~ && cd ~/nix && cd ~/dev && cd ~
# → エラーなく切り替わる

# ✅ 全部成功！direnvが完璧に動いています！
```

---

## 🎉 おめでとうございます！

これで：

- ✅ `nix develop` の手動実行が不要
- ✅ `cd` するだけで環境が切り替わる
- ✅ 2回目以降は0.1秒以下で超高速
- ✅ プロジェクトごとに異なる環境を自動管理

**もう `exec zsh` を毎回する必要はありません！**

ディレクトリを移動するだけで、適切な開発環境が自動的に利用できます。

---

## 📚 次のステップ

さらに詳しく知りたい場合：

- **DIRENV_QUICKSTART.md** - 詳細な使い方とワークフロー
- **DIRENV_SETUP.md** - 完全なセットアップガイド
- **TOOLS.md** - 他の便利なツールの説明

楽しい開発を！
