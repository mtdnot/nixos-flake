# NixOS開発環境ツール詳細リファレンス

このドキュメントでは、提案に含まれる全てのツールの詳細、使用方法、実例を説明します。

---

## 📂 目次

1. [開発ワークフロー効率化](#1-開発ワークフロー効率化)
2. [コード品質ツール](#2-コード品質ツール)
3. [モニタリング・可視化](#3-モニタリング可視化)
4. [ビルド最適化](#4-ビルド最適化)
5. [探索・デバッグツール](#5-探索デバッグツール)
6. [高度なツール（オプション）](#6-高度なツールオプション)

---

## 1. 開発ワークフロー効率化

### 🔄 direnv + nix-direnv

**概要**: プロジェクトディレクトリに入るだけで自動的に開発環境をアクティベートするツール

**リポジトリ**:
- direnv: https://github.com/direnv/direnv
- nix-direnv: https://github.com/nix-community/nix-direnv

**何が嬉しいか**:
- `nix develop`を毎回手動で実行する必要がなくなる
- プロジェクトごとに異なる開発環境が自動的に切り替わる
- nix-direnvのキャッシュ機能により、2回目以降の読み込みが超高速（0.1秒以下）
- 環境変数、PATH、シェルフックが自動的に設定される

**使い方**:

```bash
# 1. プロジェクトルートに.envrcを作成
echo "use flake" > .envrc

# 2. direnvに許可を与える
direnv allow

# 3. ディレクトリに入ると自動的に環境がアクティベート
cd /path/to/project
# → direnv: loading ~/project/.envrc
# → direnv: using flake
# → [開発環境がアクティブに]

# 4. ディレクトリを出ると自動的にデアクティベート
cd ..
# → direnv: unloading
```

**高度な使い方**:

```bash
# 特定のdevShellを指定
echo "use flake .#agentshell" > .envrc

# 環境変数を追加
cat > .envrc << 'EOF'
use flake
export CUDA_VISIBLE_DEVICES=0
export PYTHONPATH=$PWD/src:$PYTHONPATH
EOF

# レイアウトをカスタマイズ
echo "use flake --impure" > .envrc  # impure評価を許可
```

**実際の効果**:
- 手動実行: `nix develop`に毎回3-5秒かかる
- direnv初回: 3-5秒（キャッシュ構築）
- direnv 2回目以降: 0.1秒以下（超高速）

---

### 📊 nix-output-monitor (nom)

**概要**: Nixのビルドプロセスを視覚的に表示するツール

**リポジトリ**: https://github.com/maralorn/nix-output-monitor

**何が嬉しいか**:
- ビルド進捗が視覚的にわかる（プログレスバー、ツリー表示）
- 並列ビルドの状態が一目瞭然
- 各derivationのビルド時間がわかる
- エラーやWarningがカラーハイライトされる
- 大量のログに埋もれず、重要な情報だけ見える

**使い方**:

```bash
# 通常のnixコマンドの代わりにnomを使う
nom build .#nixosConfigurations.nixos-cui.config.system.build.toplevel
nom shell nixpkgs#hello
nom develop

# パイプで使う
nix build . 2>&1 | nom

# NixOSの再ビルド
sudo nom-rebuild switch
```

**表示例**:

```
Building [#############         ] 65% (13/20)
├─ hello-2.12.1 ✓ (2.3s)
├─ gcc-13.2.0 [####              ] 25% (15.2s)
│  └─ gmp-6.3.0 ✓ (1.1s)
├─ python3-3.11.6 [##########    ] 80% (45.6s)
└─ pytorch-2.1.0 [#             ] 10% (Est. 5m12s)
```

**実際の効果**:
- 通常: ログが流れるだけで進捗不明、ストレス
- nom: 視覚的フィードバックで安心、残り時間がわかる

---

### ✅ pre-commit

**概要**: Git commitの前に自動的にコード品質チェックを実行

**リポジトリ**: https://github.com/pre-commit/pre-commit

**何が嬉しいか**:
- コミット前に自動的にコードフォーマット・リント
- チーム全体で一貫したコード品質
- CIで失敗する前にローカルで検出
- 自動修正可能な問題は自動で直してくれる

**設定例** (`.pre-commit-config.yaml`):

```yaml
repos:
  - repo: local
    hooks:
      # Nixコードフォーマット
      - id: nixpkgs-fmt
        name: nixpkgs-fmt
        entry: nixpkgs-fmt
        language: system
        files: \.nix$
        pass_filenames: true

      # Nixリント（アンチパターン検出）
      - id: statix
        name: statix check
        entry: statix check
        language: system
        files: \.nix$
        pass_filenames: false

      # 未使用コード検出
      - id: deadnix
        name: deadnix
        entry: deadnix --fail
        language: system
        files: \.nix$
        pass_filenames: true

  # 追加: 一般的なチェック
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
```

**使い方**:

```bash
# インストール（devShellに入った後）
pre-commit install

# 手動実行（全ファイル）
pre-commit run --all-files

# 特定のフックのみ実行
pre-commit run nixpkgs-fmt --all-files

# フックをスキップしてコミット
git commit --no-verify -m "WIP"
```

**実際の動作**:

```bash
$ git commit -m "Add new feature"
nixpkgs-fmt..........................................Failed
- hook id: nixpkgs-fmt
- files were modified by this hook

flake.nix

statix check.........................................Passed
deadnix..............................................Passed

$ git add flake.nix  # フォーマットされたファイルを追加
$ git commit -m "Add new feature"
nixpkgs-fmt..........................................Passed
statix check.........................................Passed
deadnix..............................................Passed
[main abc1234] Add new feature
 1 file changed, 10 insertions(+)
```

---

## 2. コード品質ツール

### 🎨 nixpkgs-fmt

**概要**: nixpkgs公式のNixコードフォーマッター

**リポジトリ**: https://github.com/nix-community/nixpkgs-fmt

**何が嬉しいか**:
- nixpkgs自体で使われている公式スタイル
- 保守的で読みやすいフォーマット
- 高速（Rustで実装）
- 冪等性保証（何回実行しても同じ結果）

**使い方**:

```bash
# 単一ファイルをフォーマット
nixpkgs-fmt flake.nix

# ディレクトリ全体をフォーマット
nixpkgs-fmt .

# チェックのみ（変更しない）
nixpkgs-fmt --check flake.nix
# Exit code 0: フォーマット済み
# Exit code 1: フォーマットが必要

# 複数ファイル
nixpkgs-fmt **/*.nix
```

**フォーマット例**:

**Before**:
```nix
{pkgs,...}:{home.packages=with pkgs;[git vim];programs.zsh.enable=true;}
```

**After**:
```nix
{ pkgs, ... }: {
  home.packages = with pkgs; [
    git
    vim
  ];
  programs.zsh.enable = true;
}
```

---

### 🎯 alejandra

**概要**: より opinionated なNixフォーマッター（nixpkgs-fmtの代替）

**リポジトリ**: https://github.com/kamadorueda/alejandra

**何が嬉しいか**:
- より積極的な整形（長い行を自動で分割）
- モダンなスタイル
- 非常に高速（並列処理対応）
- Prettierに似た哲学

**使い方**:

```bash
# フォーマット
alejandra .

# チェックのみ
alejandra --check .

# 特定のファイルを除外
alejandra --exclude '**/generated/*.nix' .
```

**nixpkgs-fmt との違い**:

```nix
# nixpkgs-fmt: 保守的
{
  option = "value";
  anotherOption = "another value";
}

# alejandra: より積極的
{
  option = "value";
  anotherOption =
    "another value";
}
```

**選択の指針**:
- **nixpkgs-fmt**: nixpkgs公式スタイルに従いたい、保守的が好き
- **alejandra**: モダンなスタイル、自動分割が欲しい

---

### 🔍 statix

**概要**: Nixコードのリンター（アンチパターン検出）

**リポジトリ**: https://github.com/nerdypepper/statix

**何が嬉しいか**:
- よくある間違いを自動検出
- パフォーマンス改善の提案
- セキュリティ問題の検出
- 自動修正機能

**検出するアンチパターンの例**:

1. **空のlet-in**:
```nix
# Bad
let in pkgs.hello

# Good
pkgs.hello
```

2. **不要な inherit**:
```nix
# Bad
{ pkgs }: { inherit pkgs; }

# Good
{ pkgs }: { inherit pkgs; }  # 実際に使われている場合のみOK
```

3. **非推奨の with 使用**:
```nix
# Bad (with は scope を汚染)
with pkgs; [ git vim ]

# Good
[ pkgs.git pkgs.vim ]
```

4. **空の文字列補間**:
```nix
# Bad
"${}"

# Good
""
```

**使い方**:

```bash
# チェック
statix check .

# 自動修正
statix fix .

# 特定のルールを無効化
statix check --ignore empty_let_in .

# JSON出力（CI用）
statix check --format json .
```

**出力例**:

```
flake.nix
  7:3   warning[empty_let_in]   empty let-in expression
  12:5  error[deprecated_with]   avoid using `with` in list context
  15:8  warning[unused_binding]  unused binding `foo`

2 errors, 2 warnings
```

---

### 🧹 deadnix

**概要**: 未使用のNixコードを検出

**リポジトリ**: https://github.com/astro/deadnix

**何が嬉しいか**:
- 未使用のlet束縛を検出
- 未使用の関数引数を検出
- コードの整理に役立つ
- 自動削除機能

**検出例**:

```nix
{ pkgs, lib, config }:  # configは未使用
let
  unusedVar = "hello";  # 未使用
  usedVar = "world";
in
{
  value = usedVar;
}
```

**使い方**:

```bash
# チェック
deadnix .

# 未使用コードを自動削除
deadnix --edit .

# 関数引数のチェックのみ
deadnix --no-lambda-pattern-names .

# 特定のファイルを除外
deadnix --exclude flake.nix .
```

**出力例**:

```
flake.nix:5:3: unused let binding `unusedVar`
flake.nix:1:15: unused function argument `config`
```

---

## 3. モニタリング・可視化

### 📈 btop

**概要**: モダンで美しいシステムモニター（htopの後継）

**リポジトリ**: https://github.com/aristocratos/btop

**何が嬉しいか**:
- 美しいグラフ表示（CPU、メモリ、ディスク、ネットワーク）
- マウス操作対応
- GPUモニタリング（NVIDIA対応）
- カスタマイズ可能なテーマ
- htopより高機能で視覚的

**使い方**:

```bash
# 起動
btop

# キーバインド（起動後）
# q: 終了
# m: メニュー
# t: テーマ変更
# +/-: 更新間隔の調整
# f: フィルター
# k: プロセスをkill
```

**表示内容**:
```
CPU ▁▂▃▅▆▇█ 45%  Mem ████████░░ 8.2GB/16GB
┌────────────────────────────────────────┐
│ PID  USER   CPU%  MEM%  COMMAND        │
│ 1234 mtdnot 45.2  12.3  python train.py│
│ 5678 mtdnot 23.1   8.9  nom build      │
└────────────────────────────────────────┘

Disk I/O: ↑ 45MB/s ↓ 12MB/s
Network:  ↑ 1.2MB/s ↓ 5.3MB/s

GPU 0: GTX 4090 ████████░░ 80% | 18GB/24GB
```

**設定**:
- `~/.config/btop/btop.conf` で設定変更
- テーマ、色、更新間隔などカスタマイズ可能

---

### 🦀 bottom (btm)

**概要**: Rust製の代替システムモニター

**リポジトリ**: https://github.com/ClementTsang/bottom

**何が嬉しいか**:
- btopよりカスタマイズ性が高い
- ウィジェットベースのレイアウト
- バッテリー情報表示
- クロスプラットフォーム（Linux/macOS/Windows）

**使い方**:

```bash
# 起動
btm

# デフォルトモード
btm --default_widget_type proc

# 基本モード（シンプル表示）
btm --basic

# レートの単位を変更
btm --rate 500ms
```

---

### 🌳 nix-tree

**概要**: Nixのdependency graphを対話的に探索

**リポジトリ**: https://github.com/utdemir/nix-tree

**何が嬉しいか**:
- なぜこのパッケージが依存されているかわかる（why-depends）
- closure sizeの内訳がわかる
- 不要な依存を発見できる
- ディスク使用量の最適化に役立つ

**使い方**:

```bash
# 現在のシステムを探索
nix-tree /run/current-system

# 特定のパッケージを探索
nix-tree $(nix-build '<nixpkgs>' -A hello)

# flakeのoutputを探索
nix-tree .#nixosConfigurations.nixos-cui.config.system.build.toplevel

# derivationを直接指定
nix-tree /nix/store/...-some-package
```

**操作方法**:

```
使用中: 2.3 GB
┌─ glibc-2.38 (145 MB)
├─ gcc-13.2.0 (678 MB)
│  ├─ gmp-6.3.0 (12 MB)
│  └─ mpfr-4.2.0 (8 MB)
└─ python3-3.11.6 (234 MB)
   ├─ openssl-3.0.12 (45 MB)
   └─ sqlite-3.43.0 (23 MB)

キー操作:
- Enter: 展開/折りたたみ
- /: 検索
- w: why-dependsモード（なぜ依存されているか）
- s: サイズでソート
- q: 終了
```

**実際の使用例**:

```bash
# システムのclosureで最もサイズが大きいパッケージを見つける
nix-tree /run/current-system
# → sキーでサイズソート → gcc, llvm, pythonなどが大きいことがわかる

# なぜpythonが依存されているか調べる
# → /python で検索 → wキーでwhy-depends → どこから参照されているか確認
```

---

### 🔄 nix-diff

**概要**: 2つのNix derivationの差分を表示

**リポジトリ**: https://github.com/Gabriella439/nix-diff

**何が嬉しいか**:
- なぜ再ビルドが必要かわかる
- 設定変更の影響範囲がわかる
- NixOSのgeneration間の差分がわかる
- デバッグに超便利

**使い方**:

```bash
# 2つのderivationを比較
nix-diff \
  /nix/store/...-old.drv \
  /nix/store/...-new.drv

# NixOSの世代を比較
nix-diff \
  /nix/var/nix/profiles/system-42-link \
  /nix/var/nix/profiles/system-43-link

# flakeのbefore/afterを比較
nix-diff \
  $(nix path-info --derivation .#nixosConfigurations.nixos-cui.config.system.build.toplevel) \
  $(nix path-info --derivation .#nixosConfigurations.nixos-cui.config.system.build.toplevel --override-input nixpkgs nixpkgs/nixos-unstable)
```

**出力例**:

```
The environment variable +CC was added
The environment variable -CFLAGS was removed
The environment variable LDFLAGS changed
  -old value: "-L/nix/store/abc-glibc/lib"
  +new value: "-L/nix/store/xyz-glibc/lib"

The input named glibc changed
  -/nix/store/abc-glibc-2.37
  +/nix/store/xyz-glibc-2.38
    The input named gcc changed
      ...
```

**実際の使用例**:

```bash
# flake.lockを更新前後で比較
OLD=$(nix build . --dry-run 2>&1 | grep "will be built" | awk '{print $1}')
nix flake update
NEW=$(nix build . --dry-run 2>&1 | grep "will be built" | awk '{print $1}')
nix-diff $OLD $NEW
```

---

## 4. ビルド最適化

### 🚀 cachix

**概要**: Nixバイナリキャッシュサービス

**リポジトリ**: https://github.com/cachix/cachix
**サービス**: https://cachix.org/

**何が嬉しいか**:
- ビルド済みパッケージをダウンロード（ビルド不要）
- 特にCUDA、LLVM、GCCなど大きなパッケージで効果大
- ビルド時間を80-90%削減可能
- 無料枠あり（個人開発に十分）

**有名な公開キャッシュ**:
- `nix-community.cachix.org`: Nixコミュニティツール
- `cuda-maintainers.cachix.org`: CUDA関連パッケージ
- `devenv.cachix.org`: devenvツール
- `nixpkgs-unfree.cachix.org`: non-freeパッケージ

**設定方法**:

```nix
# configuration.nix または flake.nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
    "https://cuda-maintainers.cachix.org"
  ];

  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
  ];
};
```

**CLI使い方**:

```bash
# cachixクライアントインストール
nix-env -iA cachix -f https://cachix.org/api/v1/install

# キャッシュを使う設定を追加
cachix use nix-community
cachix use cuda-maintainers

# 自分のキャッシュを作成（要アカウント）
cachix authtoken <YOUR_TOKEN>
cachix create my-cache

# ビルド結果をキャッシュにpush
nix build . --json | jq -r '.[].outputs.out' | cachix push my-cache
```

**効果測定**:

```bash
# キャッシュなし
$ time nix build .#nixosConfigurations.nixos-cui.config.system.build.toplevel
# → 45分

# キャッシュあり
$ time nix build .#nixosConfigurations.nixos-cui.config.system.build.toplevel
# → 2分（95%削減！）
```

---

### ⚡ sccache

**概要**: C/C++/Rustコンパイルキャッシュ

**リポジトリ**: https://github.com/mozilla/sccache

**何が嬉しいか**:
- CUDAコードのコンパイル結果をキャッシュ
- 再ビルドが劇的に高速化
- クラウドストレージバックエンド対応（S3, GCS, Azure）
- ccacheの代替（より高速）

**設定例**:

```nix
# devShell内で
{
  buildInputs = [ pkgs.sccache ];

  shellHook = ''
    export CC="sccache gcc"
    export CXX="sccache g++"
    export RUSTC_WRAPPER="sccache"
    export SCCACHE_DIR="$HOME/.cache/sccache"
  '';
}
```

**使い方**:

```bash
# 統計表示
sccache --show-stats

# キャッシュクリア
sccache --zero-stats
sccache --stop-server

# 最大キャッシュサイズ設定
export SCCACHE_CACHE_SIZE="10G"
```

**効果**:
- 初回ビルド: 10分
- 2回目（キャッシュヒット）: 30秒

---

## 5. 探索・デバッグツール

### 🔧 nixos-option

**概要**: NixOS設定オプションの検索・表示ツール

**組み込み**: NixOSに標準搭載

**何が嬉しいか**:
- 設定可能なオプションを検索
- デフォルト値がわかる
- 型情報がわかる
- ドキュメントがCLIで読める

**使い方**:

```bash
# オプション検索
nixos-option services.nginx

# 現在の値を表示
nixos-option services.nginx.enable

# すべてのservicesを列挙
nixos-option services

# オプションの型とドキュメント
nixos-option -r services.postgresql.settings
```

**出力例**:

```
$ nixos-option services.nginx.enable
Value:
true

Type:
boolean

Declared in:
/nix/store/.../nixos/modules/services/web-servers/nginx/default.nix

Description:
Whether to enable the nginx web server.
```

---

### 📦 nix path-info

**概要**: store pathの情報を表示（組み込みコマンド）

**何が嬉しいか**:
- closure sizeの計算
- 依存関係の列挙
- ディスク使用量の分析

**使い方**:

```bash
# closure sizeを表示
nix path-info -rsSh /run/current-system

# 依存関係をツリー表示
nix-store -q --tree /run/current-system

# 逆依存（何に使われているか）
nix-store -q --referrers /nix/store/...-glibc

# ガベージコレクションでの削除候補
nix-store --gc --print-dead
```

**出力例**:

```
$ nix path-info -rsSh /run/current-system | sort -k2 -h | tail
/nix/store/...-gcc-13.2.0         678M  1.2G
/nix/store/...-llvm-16.0.6        892M  1.5G
/nix/store/...-python3-3.11.6     234M  890M
/nix/store/...-linux-6.6.0        145M  2.3G
```

---

## 6. 高度なツール（オプション）

### 🚀 devenv

**概要**: より高機能な開発環境管理ツール

**サイト**: https://devenv.sh/
**リポジトリ**: https://github.com/cachix/devenv

**何が嬉しいか**:
- プロセス管理（PostgreSQL, Redis, nginxなどをプロジェクト内で起動）
- pre-commitの統合がより簡単
- 言語別のテンプレート豊富
- docker-composeの代替として使える
- より宣言的な設定

**設定例** (`devenv.nix`):

```nix
{ pkgs, ... }:

{
  # パッケージ
  packages = with pkgs; [
    git
    nodejs
    postgresql
  ];

  # 言語設定
  languages.python = {
    enable = true;
    version = "3.11";
    venv.enable = true;
  };

  languages.javascript = {
    enable = true;
    npm.enable = true;
  };

  # サービス（これが強力！）
  services.postgres = {
    enable = true;
    initialDatabases = [{ name = "myapp"; }];
    listen_addresses = "127.0.0.1";
  };

  services.redis.enable = true;

  # pre-commit
  pre-commit.hooks = {
    nixpkgs-fmt.enable = true;
    statix.enable = true;
    prettier.enable = true;
  };

  # プロセス管理
  processes = {
    web.exec = "npm run dev";
    worker.exec = "python worker.py";
  };

  # 環境変数
  env = {
    DATABASE_URL = "postgresql://localhost/myapp";
    REDIS_URL = "redis://localhost:6379";
  };
}
```

**使い方**:

```bash
# devenv環境に入る
devenv shell

# サービスを起動
devenv up

# 特定のプロセスのみ起動
devenv up web

# テスト実行
devenv test
```

**devShellとの比較**:

| 機能 | devShell | devenv |
|------|----------|--------|
| パッケージ管理 | ✅ | ✅ |
| 環境変数 | ✅ | ✅ |
| サービス起動 | ❌ 手動 | ✅ 自動 |
| プロセス管理 | ❌ | ✅ |
| pre-commit統合 | 手動設定 | 宣言的 |
| 学習コスト | 低 | 中 |

---

### 🎯 nix-init

**概要**: 既存プロジェクトからNix derivationを自動生成

**リポジトリ**: https://github.com/nix-community/nix-init

**何が嬉しいか**:
- 既存プロジェクトを簡単にNixパッケージ化
- 言語を自動検出（Rust, Python, Node.js, Go, etc.）
- flake.nixを自動生成
- ベストプラクティスに従った記述

**使い方**:

```bash
# プロジェクトディレクトリで実行
nix-init

# 対話的に質問に答える
# 1. パッケージ名は？
# 2. バージョンは？
# 3. 説明は？
# 4. ライセンスは？
# etc.

# flake.nixまたはdefault.nixが生成される
```

**生成例** (Rustプロジェクト):

```nix
{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "my-tool";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "username";
    repo = "my-tool";
    rev = "v${version}";
    hash = "sha256-...";
  };

  cargoHash = "sha256-...";

  meta = with lib; {
    description = "My awesome tool";
    homepage = "https://github.com/username/my-tool";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
```

**対応言語**:
- Rust (Cargo)
- Python (pip, poetry, setuptools)
- Node.js (npm, yarn, pnpm)
- Go
- その他多数

---

### 🌟 dream2nix

**概要**: 言語別パッケージマネージャーからNix式への変換

**リポジトリ**: https://github.com/nix-community/dream2nix

**何が嬉しいか**:
- package-lock.json → Nix
- Cargo.lock → Nix
- requirements.txt → Nix
- 既存のロックファイルを活用
- 依存関係を完全に再現

**対応フォーマット**:
- **Node.js**: package-lock.json, yarn.lock, pnpm-lock.yaml
- **Python**: requirements.txt, poetry.lock, Pipfile.lock
- **Rust**: Cargo.lock
- **Go**: go.mod

**使い方**:

```bash
# CLIツール（実験的）
nix run github:nix-community/dream2nix -- init

# flakeでの統合例
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dream2nix.url = "github:nix-community/dream2nix";
  };

  outputs = { self, nixpkgs, dream2nix }:
    dream2nix.lib.makeFlakeOutputs {
      systems = [ "x86_64-linux" ];
      config.projectRoot = ./.;
      source = ./.;
    };
}
```

**Node.jsプロジェクトの例**:

```nix
# dream2nixがpackage-lock.jsonから自動生成
{
  myApp = dream2nix.lib.evalProjects {
    source = ./.;
    projects = {
      myApp = {
        name = "my-app";
        subsystem = "nodejs";
        translator = "package-lock";
      };
    };
  };
}
```

---

### 🧩 flake-parts

**概要**: モジュール化されたflake記述フレームワーク

**リポジトリ**: https://github.com/hercules-ci/flake-parts

**何が嬉しいか**:
- 大きなflake.nixをモジュールに分割
- system指定の重複を減らす
- 再利用可能なモジュール
- より宣言的な記述

**現在のflake.nix**:

```nix
{
  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default = ...;
    packages.aarch64-darwin.default = ...;
    devShells.x86_64-linux.default = ...;
    devShells.aarch64-darwin.default = ...;
    # 重複が多い！
  };
}
```

**flake-partsでの書き換え**:

```nix
{
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];

      perSystem = { pkgs, system, ... }: {
        # systemは自動で展開される
        packages.default = pkgs.hello;
        devShells.default = pkgs.mkShell { ... };
      };
    };
}
```

**モジュール分割例**:

```
flake.nix
parts/
  ├── packages.nix
  ├── devshells.nix
  ├── nixos.nix
  └── overlays.nix
```

```nix
# flake.nix
{
  outputs = inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./parts/packages.nix
        ./parts/devshells.nix
        ./parts/nixos.nix
      ];
    };
}
```

---

### 🌐 nixos-anywhere

**概要**: リモートマシンへのNixOSデプロイ自動化

**リポジトリ**: https://github.com/nix-community/nixos-anywhere

**何が嬉しいか**:
- SSH経由でNixOSをリモートインストール
- ディスクパーティショニング自動化
- disko統合（宣言的ディスク管理）
- VPS、クラウド、ベアメタルに対応

**使い方**:

```bash
# リモートマシンにNixOSをインストール
nixos-anywhere --flake '.#nixos-server' root@192.168.1.100

# カスタムディスクレイアウト
nixos-anywhere \
  --flake '.#nixos-server' \
  --disk-encryption \
  root@server.example.com
```

**disko設定例** (ディスクレイアウト):

```nix
# disk-config.nix
{
  disko.devices = {
    disk.main = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
```

---

## 📚 まとめ：ツール選択ガイド

### 優先度別導入推奨

**🔥 最優先（即座に効果）**:
1. **direnv + nix-direnv**: 自動環境アクティベーション
2. **btop**: システムモニタリング
3. **nixpkgs-fmt**: コードフォーマット
4. **cachix**: ビルド時間短縮

**⭐ 高優先（開発効率向上）**:
5. **nom**: ビルド進捗可視化
6. **statix**: コードリント
7. **pre-commit**: 自動品質チェック
8. **nix-tree**: 依存関係探索

**✅ 中優先（便利だが必須ではない）**:
9. **nix-diff**: 設定変更の理解
10. **deadnix**: コードクリーンアップ
11. **alejandra**: 代替フォーマッター

**🎯 低優先（特定用途）**:
12. **devenv**: サービス起動が必要な場合
13. **nix-init**: 新規パッケージング時
14. **dream2nix**: 既存プロジェクト変換時
15. **flake-parts**: flakeが複雑化した場合
16. **nixos-anywhere**: リモートデプロイ時

---

## 🎓 学習リソース

- **公式Wiki**: https://nixos.wiki/
- **Nix Pills**: https://nixos.org/guides/nix-pills/
- **Zero to Nix**: https://zero-to-nix.com/
- **Awesome Nix**: https://github.com/nix-community/awesome-nix
- **Discourse**: https://discourse.nixos.org/

---

これで全ツールの詳細説明が完了です！各ツールの使い方、効果、実例を理解できたと思います。
