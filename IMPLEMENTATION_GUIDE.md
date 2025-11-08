# 改善実装ガイド

このドキュメントは、[PROJECT_AUDIT_REPORT.md](./PROJECT_AUDIT_REPORT.md)で提案された改善策の実装手順を説明します。

## 目次

- [優先度1: CI/CDパイプラインの構築](#優先度1-cicdパイプラインの構築)
- [優先度2: レビュープロセスの整備](#優先度2-レビュープロセスの整備)
- [優先度3: ドキュメント整備](#優先度3-ドキュメント整備)
- [優先度4: 静的解析ツールの導入](#優先度4-静的解析ツールの導入)
- [優先度5: Issueテンプレートの整備](#優先度5-issueテンプレートの整備)

---

## 優先度1: CI/CDパイプラインの構築

### ✅ 完了済み

以下のファイルが作成されています：
- `.github/workflows/ci.yml` - 基本的なCIワークフロー

### 次のステップ

#### 1. Branch Protection Rules の設定

GitHub リポジトリの Settings → Branches → Add rule で以下を設定：

```
Branch name pattern: main

保護ルール:
☑ Require a pull request before merging
  ☑ Require approvals (1)
☑ Require status checks to pass before merging
  ☑ Require branches to be up to date before merging
  Status checks:
    - test (Build and test)
☑ Require conversation resolution before merging
☑ Do not allow bypassing the above settings
```

#### 2. Dependabot の有効化

Settings → Security → Code security and analysis で有効化：

```
☑ Dependency graph
☑ Dependabot alerts
☑ Dependabot security updates
```

#### 3. Dependabot の設定ファイル作成

`.github/dependabot.yml` を作成：

```yaml
version: 2
updates:
  # Elixir dependencies
  - package-ecosystem: "mix"
    directory: "/shooter_game"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10

  # Node.js dependencies
  - package-ecosystem: "npm"
    directory: "/shooter_game/assets"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

#### 4. CodeQL の設定（オプションだが推奨）

`.github/workflows/codeql.yml` を作成：

```yaml
name: "CodeQL"

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * 1'

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Initialize CodeQL
      uses: github/codeql-action/init@v2
      with:
        languages: javascript

    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v2
```

---

## 優先度2: レビュープロセスの整備

### ✅ 完了済み

以下のファイルが作成されています：
- `.github/PULL_REQUEST_TEMPLATE.md` - PRテンプレート
- `CONTRIBUTING.md` - コントリビューションガイド（レビューガイドラインを含む）

### 次のステップ

#### 1. レビュー文化の醸成

チーム内で以下を共有：

1. **レビューの目的**
   - コード品質の向上
   - ナレッジの共有
   - バグの早期発見

2. **レビューの観点**（CONTRIBUTING.mdより）
   - 機能性
   - コード品質
   - パフォーマンス
   - セキュリティ
   - テスト

3. **フィードバックの書き方**
   - 具体的で建設的に
   - 理由を明確に
   - 提案を含める

#### 2. レビューチェックリストの活用

PRテンプレートのチェックリストを必ず確認：

```markdown
- [ ] コードが適切にフォーマットされている
- [ ] テストが追加されている
- [ ] ドキュメントが更新されている
- [ ] コミットメッセージが明確である
- [ ] 変更規模が適切である
- [ ] セルフレビューを実施済み
```

#### 3. マージ前の必須条件

- 最低1名のレビュアーの承認
- すべてのCIチェックが通過
- すべてのレビューコメントが解決済み

---

## 優先度3: ドキュメント整備

### ✅ 完了済み

以下のファイルが作成されています：
- `README.md` - ルートREADME
- `CONTRIBUTING.md` - コントリビューションガイド
- `PROJECT_AUDIT_REPORT.md` - 監査レポート

### 次のステップ

#### 1. docs/ ディレクトリの作成

```bash
mkdir -p docs
```

以下のドキュメントを作成：

##### docs/ARCHITECTURE.md

```markdown
# アーキテクチャドキュメント

## 概要
## システム構成
## データフロー
## 技術スタック
## 設計判断の記録
```

##### docs/DEPLOYMENT.md

```markdown
# デプロイガイド

## 環境
## デプロイ手順
## ロールバック手順
## モニタリング
## トラブルシューティング
```

##### docs/TROUBLESHOOTING.md

```markdown
# トラブルシューティング

## よくある問題
## デバッグ方法
## ログの確認方法
## サポート連絡先
```

#### 2. 既存ドキュメントの定期的な更新

- README.mdの内容を最新に保つ
- 新機能追加時はドキュメントも更新
- 四半期ごとにドキュメントレビューを実施

---

## 優先度4: 静的解析ツールの導入

### ✅ 準備完了

`.credo.exs` ファイルが作成されています。

### 実装手順

#### 1. Credo の導入

`shooter_game/mix.exs` に依存関係を追加：

```elixir
defp deps do
  [
    # 既存の依存関係...
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
  ]
end
```

インストール：

```bash
cd shooter_game
mix deps.get
```

実行：

```bash
# すべてのチェックを実行
mix credo

# 厳格モード
mix credo --strict

# 特定の重要度のみ
mix credo --only warning,error
```

#### 2. Dialyxir の導入

`shooter_game/mix.exs` に依存関係を追加：

```elixir
defp deps do
  [
    # 既存の依存関係...
    {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
  ]
end
```

インストールと初回実行：

```bash
cd shooter_game
mix deps.get
mix dialyzer  # 初回は時間がかかります（PLTの構築）
```

#### 3. CI への統合

`.github/workflows/ci.yml` に以下を追加：

```yaml
    - name: Run Credo
      run: |
        cd shooter_game
        mix credo --strict

    - name: Restore PLT cache
      uses: actions/cache@v4
      with:
        path: shooter_game/priv/plts
        key: ${{ runner.os }}-plt-${{ hashFiles('shooter_game/mix.lock') }}
        restore-keys: ${{ runner.os }}-plt-

    - name: Run Dialyzer
      run: |
        cd shooter_game
        mix dialyzer --format github
```

#### 4. mix.exs の precommit エイリアスに追加

```elixir
defp aliases do
  [
    # 既存のエイリアス...
    precommit: [
      "compile --warning-as-errors",
      "deps.unlock --unused",
      "format",
      "credo --strict",
      "test"
    ]
  ]
end
```

#### 5. 型仕様の追加（Dialyzer用）

重要な公開関数に型仕様を追加：

```elixir
@spec calculate_score(integer()) :: integer()
def calculate_score(points) do
  points * 10
end
```

---

## 優先度5: Issueテンプレートの整備

### ✅ 完了済み

以下のテンプレートが作成されています：
- `.github/ISSUE_TEMPLATE/bug_report.md` - バグレポート
- `.github/ISSUE_TEMPLATE/feature_request.md` - 機能要望

### 次のステップ

#### 1. 追加のテンプレート作成（オプション）

##### .github/ISSUE_TEMPLATE/question.md

```yaml
---
name: 質問
about: プロジェクトに関する質問をする
title: '[QUESTION] '
labels: question
assignees: ''
---

## 質問内容

<!-- 質問を明確に記載してください -->

## 試したこと

<!-- すでに試したことがあれば記載してください -->

## 参考情報

<!-- 参考になる情報があれば記載してください -->
```

##### .github/ISSUE_TEMPLATE/documentation.md

```yaml
---
name: ドキュメント改善
about: ドキュメントの改善を提案する
title: '[DOCS] '
labels: documentation
assignees: ''
---

## 対象ドキュメント

<!-- 改善したいドキュメントを指定してください -->

## 現状の問題

<!-- 現在のドキュメントの問題点を説明してください -->

## 改善案

<!-- どのように改善すべきか提案してください -->
```

#### 2. Issue テンプレート選択画面の設定

`.github/ISSUE_TEMPLATE/config.yml` を作成：

```yaml
blank_issues_enabled: false
contact_links:
  - name: 💬 ディスカッション
    url: https://github.com/RyoWakabayashi/spec_kit_test/discussions
    about: 一般的な議論や質問はこちら（Discussionsが有効な場合）
```

#### 3. ラベルの整備

GitHub の Issues → Labels で以下のラベルを作成：

```
優先度:
- priority: high (赤色)
- priority: medium (黄色)
- priority: low (緑色)

種類:
- bug (赤色)
- enhancement (青色)
- documentation (水色)
- question (紫色)
- good first issue (緑色)
- help wanted (オレンジ色)

状態:
- wip (作業中)
- blocked (ブロック中)
- needs review (レビュー待ち)
```

---

## テストカバレッジの可視化（追加推奨事項）

### ExCoveralls の導入

#### 1. 依存関係の追加

`shooter_game/mix.exs`:

```elixir
defp deps do
  [
    # 既存の依存関係...
    {:excoveralls, "~> 0.18", only: :test}
  ]
end

def project do
  [
    # 既存の設定...
    test_coverage: [tool: ExCoveralls],
    preferred_cli_env: [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.json": :test
    ]
  ]
end
```

#### 2. 使用方法

```bash
# カバレッジレポート生成
mix coveralls

# HTML形式
mix coveralls.html
# cover/excoveralls.html をブラウザで開く

# 詳細表示
mix coveralls.detail
```

#### 3. CI への統合

```yaml
    - name: Run tests with coverage
      run: |
        cd shooter_game
        mix coveralls.json
      env:
        MIX_ENV: test

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./shooter_game/cover/excoveralls.json
        flags: unittests
        name: codecov-umbrella
```

---

## 進捗管理

### 実装チェックリスト

#### フェーズ1: 基礎構築（完了）
- [x] CI/CDパイプラインの基本構築
- [x] PRテンプレートの作成
- [x] ルートREADME.md の作成
- [x] CONTRIBUTING.md の作成
- [ ] Branch Protection Rules の設定（GitHub UI）
- [ ] Dependabot の有効化（GitHub UI）

#### フェーズ2: プロセス整備
- [x] Issueテンプレートの作成
- [ ] レビューガイドラインの周知
- [ ] コミットメッセージ規約の適用
- [ ] ラベルの整備

#### フェーズ3: 品質向上
- [x] Credoの設定ファイル作成
- [ ] Credoの依存関係追加
- [ ] Dialyxirの依存関係追加
- [ ] CIへの静的解析統合
- [ ] テストカバレッジの可視化

#### フェーズ4: 継続的改善
- [ ] docs/ディレクトリの整備
- [ ] アーキテクチャドキュメント作成
- [ ] デプロイガイド作成
- [ ] メトリクスダッシュボードの検討

---

## 実装後の確認事項

各フェーズ完了後に以下を確認：

### CI/CD
- [ ] PRに対してCIが自動実行される
- [ ] mainブランチへの直接pushが拒否される
- [ ] レビュー承認なしでマージできない

### ドキュメント
- [ ] 新規参入者がREADMEを読んで環境構築できる
- [ ] CONTRIBUTING.mdに従ってPRを作成できる
- [ ] 各種テンプレートが使いやすい

### 静的解析
- [ ] mix credoで警告が出ない
- [ ] mix dialyzerでエラーが出ない
- [ ] CIで静的解析が実行される

### レビュープロセス
- [ ] PRテンプレートが自動的に適用される
- [ ] レビューコメントが建設的である
- [ ] マージまでのリードタイムが適切

---

## サポート

実装中に問題が発生した場合：

1. **このガイド**を再度確認
2. **CONTRIBUTING.md**のトラブルシューティングを確認
3. **Issue**を作成して質問

---

**実装を開始する前に、[PROJECT_AUDIT_REPORT.md](./PROJECT_AUDIT_REPORT.md)を再度確認することをお勧めします。**
