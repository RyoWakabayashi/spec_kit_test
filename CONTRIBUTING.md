# コントリビューションガイド

spec_kit_test プロジェクトへの貢献に興味を持っていただきありがとうございます！

このドキュメントでは、プロジェクトへの貢献方法について説明します。

## 目次

- [行動規範](#行動規範)
- [開発フロー](#開発フロー)
- [コーディング規約](#コーディング規約)
- [コミットメッセージ規約](#コミットメッセージ規約)
- [プルリクエストのガイドライン](#プルリクエストのガイドライン)
- [テストの書き方](#テストの書き方)
- [レビュープロセス](#レビュープロセス)

## 行動規範

- 互いに尊重し、建設的なコミュニケーションを心がけてください
- 多様性を尊重し、包括的な環境を維持してください
- 技術的な議論は事実とデータに基づいて行ってください
- 初心者にも優しく、質問を歓迎してください

## 開発フロー

### 1. Issue の作成

新しい機能追加やバグ修正を始める前に、まず Issue を作成してください。

- バグの場合: [バグレポートテンプレート](.github/ISSUE_TEMPLATE/bug_report.md)を使用
- 機能追加の場合: [機能要望テンプレート](.github/ISSUE_TEMPLATE/feature_request.md)を使用

### 2. ブランチの作成

```bash
# mainブランチから最新のコードを取得
git checkout main
git pull origin main

# 新しいブランチを作成
git checkout -b feature/your-feature-name
# または
git checkout -b fix/bug-description
```

**ブランチ命名規則**:
- 機能追加: `feature/機能名`
- バグ修正: `fix/バグの説明`
- ドキュメント: `docs/内容`
- リファクタリング: `refactor/対象`

### 3. 開発

#### 環境構築

```bash
cd shooter_game

# 依存関係のインストール
mix deps.get
cd assets && npm install && cd ..

# データベースのセットアップ（必要な場合）
mix ecto.setup

# サーバー起動
mix phx.server
```

#### 開発中の確認

```bash
# テストの実行
mix test

# コードフォーマット
mix format

# コンパイル（警告をチェック）
mix compile --warnings-as-errors
```

### 4. テストの追加

新しい機能を追加する場合は、必ずテストを追加してください。

テストファイルは `test/` ディレクトリ以下に配置します。

```elixir
# test/shooter_game/your_module_test.exs
defmodule ShooterGame.YourModuleTest do
  use ExUnit.Case, async: true

  alias ShooterGame.YourModule

  describe "your_function/1" do
    test "正常系のテスト" do
      assert YourModule.your_function(input) == expected_output
    end

    test "異常系のテスト" do
      assert_raise ArgumentError, fn ->
        YourModule.your_function(invalid_input)
      end
    end
  end
end
```

### 5. コミット

```bash
# 変更をステージング
git add .

# コミット（メッセージ規約に従う）
git commit -m "feat: 新機能の追加"

# リモートにプッシュ
git push origin feature/your-feature-name
```

### 6. Pull Request の作成

GitHub上でPull Requestを作成してください。

- [PRテンプレート](.github/PULL_REQUEST_TEMPLATE.md)に従って記入
- すべてのチェックボックスを確認
- レビュアーを指定（推奨）

## コーディング規約

### Elixir

#### 基本ルール

- Elixir標準のスタイルガイドに従う
- `mix format` を実行して自動フォーマット
- 関数は小さく、単一責任の原則を守る
- 適切なドキュメントコメント（`@doc`, `@moduledoc`）を記述

#### 命名規則

```elixir
# モジュール名: PascalCase
defmodule ShooterGame.GameLogic do
end

# 関数名: snake_case
def calculate_score(points) do
end

# 変数名: snake_case
current_state = %{}

# 定数: @で始まる大文字のSNAKE_CASE
@default_timeout 5000
```

#### コメント

```elixir
# 公開関数には @doc を記述
@doc """
スコアを計算します。

## Examples

    iex> calculate_score(10)
    100

"""
def calculate_score(points) do
  points * 10
end
```

### JavaScript/TypeScript

- ES6以降の構文を使用
- セミコロンを使用
- シングルクォートを使用
- 適切な変数スコープ（const/let）

### ファイル構成

```
shooter_game/
├── lib/
│   ├── shooter_game/      # ビジネスロジック
│   ├── shooter_game_web/  # Webレイヤー
│   └── shooter_game.ex    # アプリケーションエントリポイント
├── test/
│   ├── shooter_game/      # ロジックのテスト
│   └── shooter_game_web/  # Webのテスト
└── assets/               # フロントエンドアセット
```

## コミットメッセージ規約

Conventional Commits形式を使用します。

### フォーマット

```
<type>: <subject>

<body>

<footer>
```

### Type

- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメントのみの変更
- `style`: コードの意味に影響を与えない変更（空白、フォーマット等）
- `refactor`: バグ修正や機能追加を伴わないコード変更
- `perf`: パフォーマンス改善
- `test`: テストの追加・修正
- `chore`: ビルドプロセスやツールの変更

### 例

```bash
# 良い例
git commit -m "feat: 敵の新しい移動パターンを追加"
git commit -m "fix: スコア計算のバグを修正"
git commit -m "docs: READMEにインストール手順を追加"

# 悪い例
git commit -m "update" # 何を更新したか不明
git commit -m "WIP" # 作業中のコミットはPRに含めない
```

### 詳細な説明が必要な場合

```bash
git commit -m "feat: 難易度調整システムの実装

プレイヤーのスコアに応じて敵の出現頻度と
移動速度を動的に調整する機能を追加しました。

Closes #42"
```

## プルリクエストのガイドライン

### サイズ

- **1つのPRは1つの目的に集中**させる
- 変更行数の目安: **300-500行以内**
- 大きな変更は複数のPRに分割する

### レビュー前チェックリスト

- [ ] すべてのテストがパスする (`mix test`)
- [ ] コードがフォーマットされている (`mix format`)
- [ ] コンパイル時に警告が出ない
- [ ] 新機能にはテストが追加されている
- [ ] ドキュメントが更新されている（必要な場合）
- [ ] PRテンプレートがすべて記入されている
- [ ] セルフレビューを実施済み

### PRのタイトル

コミットメッセージと同じ規約に従います。

```
feat: 新機能の説明
fix: バグ修正の説明
docs: ドキュメント更新の説明
```

### PRの説明

- **変更内容**: 何を実装したか
- **変更の理由**: なぜこの変更が必要か
- **テスト方法**: どのようにテストしたか
- **スクリーンショット**: UI変更がある場合

## テストの書き方

### テストの種類

1. **単体テスト**: 個別のモジュール・関数をテスト
2. **統合テスト**: 複数のモジュールの連携をテスト
3. **E2Eテスト**: LiveViewの動作をテスト

### テストのベストプラクティス

```elixir
defmodule ShooterGame.GameTest do
  use ExUnit.Case, async: true

  describe "start_game/1" do
    test "初期状態でゲームを開始できる" do
      # Arrange (準備)
      player = %{x: 0, y: 0}
      
      # Act (実行)
      result = Game.start_game(player)
      
      # Assert (検証)
      assert result.status == :playing
      assert result.score == 0
    end

    test "不正な入力でエラーを返す" do
      assert_raise ArgumentError, fn ->
        Game.start_game(nil)
      end
    end
  end
end
```

### テストカバレッジ

- 重要なビジネスロジックは100%のカバレッジを目指す
- 正常系だけでなく、異常系もテストする
- エッジケースを考慮する

## レビュープロセス

### レビュアーの役割

- コードの品質を確認
- バグの可能性を指摘
- より良い実装方法を提案
- ドキュメントの妥当性を確認

### レビューの観点

1. **機能性**: 要件を満たしているか
2. **コード品質**: 読みやすく、保守しやすいか
3. **パフォーマンス**: 性能問題はないか
4. **セキュリティ**: セキュリティリスクはないか
5. **テスト**: 適切にテストされているか

### フィードバックの書き方

```markdown
# 良いフィードバック例

**Suggestion**: この部分は関数に切り出すと、再利用性が向上します。

**Question**: ここでnilが渡される可能性はありますか？

**Nit** (些細な指摘): 変数名を `x` より `position_x` の方が分かりやすいです。

# 避けるべきフィードバック
- "これは良くない" （理由が不明）
- "自分ならこうする" （押し付け）
```

### マージの条件

- [ ] 最低1名のレビュアーの承認
- [ ] すべてのCIチェックが通過
- [ ] レビューコメントがすべて解決済み
- [ ] コンフリクトが解決済み

## トラブルシューティング

### テストが失敗する

```bash
# データベースをリセット
mix ecto.reset

# 依存関係を再インストール
rm -rf deps _build
mix deps.get
```

### フォーマットエラー

```bash
# 自動フォーマット実行
mix format
```

### コンパイルエラー

```bash
# クリーンビルド
mix clean
mix compile
```

## 質問やサポート

- **バグ報告**: [Issue](https://github.com/RyoWakabayashi/spec_kit_test/issues)を作成
- **質問**: Issueで質問用のラベルを付けて作成
- **議論**: [Discussions](https://github.com/RyoWakabayashi/spec_kit_test/discussions)（有効な場合）

## 参考資料

- [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- [Phoenix Framework Guides](https://hexdocs.pm/phoenix/overview.html)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/)

---

**ハッピーコーディング！** 🎉
