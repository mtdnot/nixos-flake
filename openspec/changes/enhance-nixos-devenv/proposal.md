# Change: Enhance NixOS Development Environment

## Why

現在のNixOS開発環境は基本的な設定のみで、開発効率を大幅に向上させる可能性のある多くの最新ツールや手法が活用されていません。以下の課題があります:

1. **開発ワークフローの可視性不足**: システムリソース監視、ビルドキャッシュ管理、flake更新管理などの可視化が不十分
2. **モダンな開発ツールの未活用**: direnv、nix-direnv、devenv、cachixなどの効率化ツールが未導入
3. **デバッグ・トラブルシューティング支援の欠如**: nix-tree、nix-diff、nixos-optionなどの探索ツールが未設定
4. **コード品質・自動化の不足**: pre-commit hooks、formatters、lintersの体系的な設定が未整備

## What Changes

以下の4つの領域で開発環境を強化します:

### 1. 開発ワークフロー効率化
- **direnv + nix-direnv**: プロジェクトディレクトリに入るだけで自動的に開発環境をアクティベート
- **devenv**: より高機能な開発環境管理ツール（プロセス管理、サービス起動など）
- **flake-update automation**: 定期的なdependency更新チェックの自動化
- **nix-output-monitor (nom)**: ビルドプロセスの視覚的な進捗表示

### 2. モニタリング・可視性向上
- **btop/bottom**: 高機能なシステムモニター（htopの代替）
- **nix-tree**: dependency graphの対話的探索
- **nix-diff**: 設定変更の差分可視化
- **nixos-option**: システム設定の探索・検索ツール

### 3. ビルド効率化
- **cachix**: バイナリキャッシュの活用でビルド時間短縮
- **nix-fast-build**: 並列ビルドの最適化
- **sccache**: C/C++/Rustコンパイルキャッシュ（CUDA開発用）

### 4. コード品質・自動化
- **pre-commit hooks**: nixpkgs-fmt、statix、deadnix自動実行
- **alejandra/nixpkgs-fmt**: Nixコードフォーマッター
- **statix**: Nixコードlinter（アンチパターン検出）
- **deadnix**: 未使用コードの検出

### 5. 興味深いツール・新しい考え方
- **nix-init**: 既存プロジェクトからNix derivationの自動生成
- **dream2nix**: 言語別パッケージマネージャー(npm/pip/cargo)からNix式への変換
- **flake-parts**: モジュール化されたflake構成の記述
- **nixos-anywhere**: リモートマシンへのNixOSデプロイ自動化

## Impact

### Affected specs
- `dev-workflow`: 新規 - 開発ワークフロー効率化
- `tooling`: 新規 - ツール導入と設定
- `monitoring`: 新規 - システム監視と可視化

### Affected code
- `flake.nix`: devShellsへの新規ツール追加、overlaysの拡張
- `modules/common/home.nix`: ユーザー環境へのツール追加
- `hosts/nixos-cui/configuration.nix`: システムレベルサービスの追加
- 新規ファイル: `.envrc`, `devenv.nix`, `.pre-commit-config.yaml`

### Benefits
- ビルド時間の短縮（cachixにより最大80%削減可能）
- 開発環境セットアップの自動化（direnv）
- コード品質の自動担保（pre-commit）
- システム状態の可視化向上（モニタリングツール）
- デバッグ効率の向上（探索ツール）

### Migration Path
段階的導入が可能で、既存環境を破壊しません:
1. Phase 1: 基本的な開発ツール導入（direnv, btop, formatters）
2. Phase 2: キャッシュとビルド最適化（cachix, nom）
3. Phase 3: 高度なツールと自動化（devenv, pre-commit, nix-init）
