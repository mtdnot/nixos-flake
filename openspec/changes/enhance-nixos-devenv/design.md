# Design: NixOS Development Environment Enhancement

## Context

現在のNixOS開発環境は以下の構成:
- flake-based設定（nixpkgs 24.11 + unstable overlay）
- 2つのdevShell: `default` (PyTorch/CUDA), `agentshell` (OpenSpec/Node.js)
- home-manager統合によるユーザー環境管理
- NVIDIA GPUサポート、Docker統合

この設計では、既存環境を維持しながら開発効率を向上させるツールを段階的に導入します。

## Goals / Non-Goals

### Goals
1. **開発者体験の向上**: 環境セットアップ自動化、視覚的フィードバック強化
2. **ビルド時間の短縮**: バイナリキャッシュ活用、効率的なビルドツール導入
3. **コード品質の自動化**: フォーマット・リントを開発フローに統合
4. **学習と探索の支援**: Nix ecosystemを理解しやすくするツール提供
5. **既存環境の維持**: PyTorch/CUDA環境やOpenSpec環境を破壊しない

### Non-Goals
1. 既存のflake構造の大幅な再構築
2. 全てのツールを一度に導入（段階的導入を優先）
3. 実験的すぎるツールの採用（安定性を重視）
4. システム全体の再インストール

## Decisions

### Decision 1: direnvを自動環境アクティベーションの基盤とする

**Why**:
- Nixコミュニティで最も広く採用されている
- nix-direnvプラグインによりflake対応が完璧
- zshとの統合が簡単
- プロジェクトごとの環境分離が自動的

**Alternatives considered**:
- `nix develop --command zsh`: 手動で毎回実行が必要、UX悪い
- `devenv`: より高機能だが、まずはdirenvで基盤を作る
- シェルスクリプト: 再発明、エラーが起きやすい

**Implementation**:
```nix
# home.nix
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
  enableZshIntegration = true;
};
```

### Decision 2: cachixをバイナリキャッシュソリューションとして採用

**Why**:
- NixOSエコシステムのデファクトスタンダード
- 無料枠で個人開発に十分
- CUDA/PyTorchなど大きなパッケージのビルド回避に効果的
- 公式キャッシュ(cache.nixos.org)との併用が容易

**Alternatives considered**:
- 独自のバイナリキャッシュサーバー: オーバーキル、メンテナンス負荷
- Hydra: 個人開発には複雑すぎる
- キャッシュなし: ビルド時間が長すぎる（特にPyTorch）

**Configuration**:
```nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org"
    "https://cuda-maintainers.cachix.org"  # CUDA用
    "https://nix-community.cachix.org"     # コミュニティツール用
  ];
  trusted-public-keys = [
    # ... keys
  ];
};
```

### Decision 3: 複数のフォーマッター（nixpkgs-fmt + alejandra）を提供

**Why**:
- コミュニティで両方使われており、好みが分かれる
- alejandra: より opinionated、自動整形が強力
- nixpkgs-fmt: nixpkgs公式準拠、保守的
- ユーザーが選択できるようにする

**Implementation**:
pre-commitではデフォルトでnixpkgs-fmtを使用し、alejandraはオプション扱い

### Decision 4: devenvは"Phase 5"としてオプション扱い

**Why**:
- 既存のdevShell構成が十分機能している
- devenvは強力だが学習コストがある
- まずdirenvでワークフロー改善を体験してから判断

**When to consider devenv**:
- サービス起動が必要になったとき（PostgreSQL, Redisなど）
- 複数開発者での環境統一が必要になったとき
- より宣言的なプロセス管理が必要になったとき

### Decision 5: ツールは主にdevShellではなくhome.nixに配置

**Why**:
- モニタリングツール（btop）やフォーマッター（nixpkgs-fmt）は常に利用可能であるべき
- devShellは特定プロジェクト用の一時環境
- グローバルに使いたいツールとプロジェクト固有ツールを分離

**Exception**:
- nix-init, dream2nixなど実験的ツールはdevShellに配置
- プロジェクト固有のビルドツールもdevShellに配置

## Architecture

### Tool Distribution Strategy

```
┌─────────────────────────────────────────┐
│ System Level (configuration.nix)       │
│ - cachix configuration                 │
│ - nix.settings optimizations           │
│ - systemd timers for updates           │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ User Level (home.nix)                   │
│ - direnv + nix-direnv                   │
│ - btop/bottom                           │
│ - nixpkgs-fmt, alejandra                │
│ - statix, deadnix                       │
│ - nix-tree, nix-diff                    │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ Project Level (devShell)                │
│ - nix-output-monitor (nom)              │
│ - pre-commit                            │
│ - project-specific tools                │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ Experimental (optional devShell)        │
│ - nix-init                              │
│ - dream2nix                             │
│ - devenv                                │
└─────────────────────────────────────────┘
```

### Integration Points

1. **direnv + flake**: `.envrc` → `use flake` → automatic devShell activation
2. **pre-commit + direnv**: hooks installed when entering directory
3. **cachix + nix.conf**: automatic binary cache lookup
4. **nom + aliases**: `nom build` instead of `nix build`

## Risks / Trade-offs

### Risk 1: direnv初回ロード時間
- **Mitigation**: nix-direnvがevaluation結果をキャッシュ、2回目以降は高速

### Risk 2: cachixの公開キャッシュ使用による信頼性問題
- **Mitigation**: trusted-public-keysで署名検証、公式・信頼されたキャッシュのみ使用

### Risk 3: pre-commitフックが開発速度を下げる
- **Mitigation**:
  - 軽量なチェックのみデフォルト有効
  - `--no-verify`でスキップ可能
  - CIでも同じチェック実行で早期発見

### Risk 4: 多数のツール導入による複雑性
- **Mitigation**:
  - 段階的導入（Phase 1-6）
  - 各ツールの明確なユースケース文書化
  - 最小限の設定でまず動かす

### Trade-off: alejandra vs nixpkgs-fmt
- alejandraの方がモダンだが、nixpkgs公式ではない
- → 両方提供し、プロジェクトで選択可能に

## Migration Plan

### Phase 1: 即座に効果のある基本ツール (1-2 days)
1. direnv + nix-direnv導入
2. btop導入
3. .envrc作成
4. 動作確認

**Rollback**: `programs.direnv.enable = false;` で無効化

### Phase 2: コード品質ツール (1 day)
1. formatters, lintersインストール
2. pre-commit設定
3. 既存コードにフォーマット適用

**Rollback**: pre-commitアンインストール、.pre-commit-config.yaml削除

### Phase 3: ビルド最適化 (1 day)
1. cachix設定追加
2. nom導入
3. ビルド時間測定

**Rollback**: cachixの設定行をコメントアウト

### Phase 4-6: 段階的な高度なツール導入 (optional, as needed)

### Validation per Phase
- 各フェーズ後に `nixos-rebuild test` で動作確認
- `nixos-rebuild switch`は確認後のみ実行
- 問題があれば `nixos-rebuild --rollback`

## Open Questions

1. **Q**: cachixのどの公開キャッシュを利用するか？
   **A**: まずは`nix-community.cachix.org`と`cuda-maintainers.cachix.org`から開始

2. **Q**: devenvは本当に必要か？
   **A**: Phase 5で評価、現時点では不要と判断

3. **Q**: flake-partsへの移行は？
   **A**: 現在のflake.nixが十分シンプルなので、複雑化してから検討

4. **Q**: システム全体のフォーマットルールをどうするか？
   **A**: nixpkgs-fmtをデフォルトとし、プロジェクトごとに変更可能

## References

- [direnv wiki](https://github.com/direnv/direnv/wiki)
- [nix-direnv](https://github.com/nix-community/nix-direnv)
- [cachix documentation](https://docs.cachix.org/)
- [devenv](https://devenv.sh/)
- [Nix community tools](https://nix-community.github.io/)
