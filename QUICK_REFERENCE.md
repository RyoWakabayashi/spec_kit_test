# クイックリファレンス

プロジェクトで日常的に使用するコマンドとプロセスのリファレンスです。

## 📖 どのドキュメントを読むべき？

| 目的 | ドキュメント |
|-----|------------|
| **プロジェクト全体を理解したい** | [README.md](./README.md) |
| **開発を始めたい** | [CONTRIBUTING.md](./CONTRIBUTING.md) |
| **監査結果を知りたい（要約版）** | [監査サマリー.md](./監査サマリー.md) |
| **監査結果を知りたい（詳細版）** | [PROJECT_AUDIT_REPORT.md](./PROJECT_AUDIT_REPORT.md) |
| **改善策を実装したい** | [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) |
| **このページ** | 日常的なコマンドとフロー |

---

## 🚀 開発フロー（5ステップ）

```
1. Issue作成 → 2. ブランチ作成 → 3. 開発 → 4. PR作成 → 5. マージ
```

### 1. Issue作成

```
GitHub → Issues → New Issue → テンプレート選択
- バグ報告 or 機能要望
```

### 2. ブランチ作成

```bash
git checkout main
git pull origin main
git checkout -b feature/your-feature-name
```

**命名規則**:
- `feature/機能名` - 新機能
- `fix/バグ説明` - バグ修正
- `docs/内容` - ドキュメント

### 3. 開発

```bash
cd shooter_game

# 依存関係インストール
mix deps.get

# 開発サーバー起動
mix phx.server
# → http://localhost:4000

# テスト実行
mix test

# フォーマット
mix format

# すべてまとめて実行
mix precommit
```

### 4. PR作成

```bash
# コミット
git add .
git commit -m "feat: 新機能の説明"

# プッシュ
git push origin feature/your-feature-name

# GitHub でPR作成
# → PRテンプレートに従って記入
```

### 5. マージ

```
レビュー待ち → レビュー → CI通過 → マージ
```

---

## 💻 よく使うコマンド

### 環境セットアップ

```bash
# 初回セットアップ
cd shooter_game
mix setup

# アセットのインストール
cd assets
npm install
cd ..
```

### 開発中

```bash
# サーバー起動
mix phx.server

# iex で起動（デバッグ用）
iex -S mix phx.server

# テスト実行
mix test

# 特定のテストのみ
mix test test/path/to/test_file.exs

# watchモード（ファイル変更時に自動実行）
mix test.watch

# フォーマットチェック
mix format --check-formatted

# フォーマット実行
mix format
```

### コミット前チェック

```bash
# すべてまとめて実行
mix precommit

# 内容:
# - コンパイル（警告をエラー扱い）
# - 未使用の依存関係チェック
# - フォーマット
# - テスト実行
```

### Credo（静的解析）

```bash
# インストール後
mix credo

# 厳格モード
mix credo --strict

# 特定の重要度のみ
mix credo --only warning,error
```

---

## 📝 コミットメッセージ規約

### フォーマット

```
<type>: <subject>

<body>（オプション）
```

### Type一覧

| Type | 説明 | 例 |
|------|------|---|
| `feat` | 新機能 | `feat: プレイヤー移動速度を調整` |
| `fix` | バグ修正 | `fix: スコア計算のバグを修正` |
| `docs` | ドキュメント | `docs: READMEに環境構築手順を追加` |
| `style` | フォーマット変更 | `style: インデントを修正` |
| `refactor` | リファクタリング | `refactor: 敵生成ロジックを整理` |
| `test` | テスト追加/修正 | `test: collision検証テストを追加` |
| `chore` | その他 | `chore: 依存関係を更新` |

### 良い例

```bash
git commit -m "feat: 難易度調整システムを実装"

git commit -m "fix: 敵が画面外に出るバグを修正

プレイヤーが高速移動時に敵の位置計算が
正しく行われない問題を修正しました。

Fixes #42"
```

### 悪い例

```bash
git commit -m "update"  # ❌ 何を更新？
git commit -m "fix bug"  # ❌ どのバグ？
git commit -m "WIP"      # ❌ 作業中はコミットしない
```

---

## 🔍 トラブルシューティング

### テストが失敗する

```bash
# データベースリセット
mix ecto.reset

# 依存関係を再インストール
rm -rf deps _build
mix deps.get
mix deps.compile
```

### コンパイルエラー

```bash
# クリーンビルド
mix clean
mix compile
```

### アセットビルドエラー

```bash
cd assets
rm -rf node_modules package-lock.json
npm install
cd ..
mix assets.build
```

### サーバーが起動しない

```bash
# ポート4000が使用中か確認
lsof -i :4000

# プロセスを停止
kill -9 <PID>

# 再起動
mix phx.server
```

---

## 🎯 PRチェックリスト

PRを作成する前に確認：

```
- [ ] mix test がパスする
- [ ] mix format 実行済み
- [ ] 新機能にテストを追加
- [ ] ドキュメントを更新（必要な場合）
- [ ] コミットメッセージが規約に準拠
- [ ] PR説明が詳細
- [ ] セルフレビュー実施済み
```

---

## 🏷️ よく使うGitコマンド

### ブランチ操作

```bash
# ブランチ一覧
git branch

# ブランチ切り替え
git checkout branch-name

# ブランチ削除
git branch -d branch-name

# リモートの変更を取得
git fetch origin

# mainブランチの最新を取り込む
git checkout main
git pull origin main
git checkout your-branch
git merge main
```

### 変更の確認

```bash
# 変更ファイル一覧
git status

# 変更内容確認
git diff

# コミット履歴
git log --oneline -10

# 特定のコミットの詳細
git show <commit-hash>
```

### 変更の取り消し

```bash
# ファイルの変更を取り消し
git checkout -- file.txt

# ステージングを取り消し
git reset HEAD file.txt

# 直前のコミットを修正
git commit --amend
```

---

## 🔗 便利なリンク

### ドキュメント

- [Elixir公式](https://elixir-lang.org/)
- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/)

### ツール

- [ExDoc](https://hexdocs.pm/ex_doc/) - ドキュメント生成
- [Credo](https://github.com/rrrene/credo) - 静的解析
- [Dialyxir](https://github.com/jeremyjh/dialyxir) - 型チェック

---

## 📞 困ったら

1. このドキュメントを確認
2. [CONTRIBUTING.md](./CONTRIBUTING.md) のトラブルシューティングを確認
3. [Issue](https://github.com/RyoWakabayashi/spec_kit_test/issues)を作成して質問

---

## 🎨 エディタ設定

### VS Code推奨拡張機能

```json
{
  "recommendations": [
    "jakebecker.elixir-ls",
    "phoenixframework.phoenix",
    "bradlc.vscode-tailwindcss"
  ]
}
```

### .editorconfig

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.{ex,exs}]
indent_style = space
indent_size = 2

[*.{js,jsx,ts,tsx}]
indent_style = space
indent_size = 2
```

---

**このドキュメントは定期的に更新されます。最新版は常にこのファイルを参照してください。**

最終更新: 2025-11-08
