# spec_kit_test

Spec Kit のテストリポジトリ

このリポジトリは、Spec Kit を使用したプロジェクト開発のテストとして作成されています。

## プロジェクト構成

```
spec_kit_test/
├── shooter_game/          # Phoenix LiveViewで作成したブラウザシューティングゲーム
├── specs/                 # 仕様ドキュメント（Spec Kit形式）
│   ├── 001-browser-shooter-game/
│   └── 002-enemy-difficulty-scaling/
├── .github/              # GitHub設定ファイル
│   ├── workflows/        # CI/CDワークフロー
│   └── ISSUE_TEMPLATE/   # Issueテンプレート
└── docs/                 # プロジェクトドキュメント（予定）
```

## プロジェクト一覧

### 🎮 Shooter Game

Phoenix LiveViewを使用したリアルタイムブラウザシューティングゲーム。

- **ディレクトリ**: `shooter_game/`
- **技術スタック**: Elixir, Phoenix, LiveView
- **詳細**: [shooter_game/README.md](./shooter_game/README.md)

**主な機能**:
- リアルタイム対戦
- 敵AIによる自動攻撃
- スコアシステム
- ハイスコアの永続化

## 開発環境のセットアップ

### 必要な環境

- Elixir (1.15以上)
- Erlang (26.x以上)
- Node.js (18.x以上)
- PostgreSQL (15.x以上)

### mise を使用したセットアップ（推奨）

```bash
# mise のインストール（未インストールの場合）
curl https://mise.run | sh

# 依存関係のインストール
mise install

# Elixir/Erlangのバージョン確認
elixir --version
```

### 手動セットアップ

各プロジェクトのREADMEを参照してください。

- [Shooter Game のセットアップ](./shooter_game/README.md#quick-start)

## 開発フロー

1. **Issue の作成**: 機能追加やバグ修正の前に Issue を作成
2. **ブランチの作成**: `feature/xxx` または `fix/xxx` の形式
3. **開発とテスト**: コードを書いてテストを追加
4. **Pull Request**: mainブランチへのPRを作成
5. **レビュー**: レビュアーによる確認
6. **マージ**: CI通過後にマージ

詳細は [CONTRIBUTING.md](./CONTRIBUTING.md) を参照してください。

## コマンド

### テストの実行

```bash
cd shooter_game
mix test
```

### コードフォーマット

```bash
cd shooter_game
mix format
```

### サーバー起動

```bash
cd shooter_game
mix phx.server
# http://localhost:4000 にアクセス
```

## ドキュメント

- [プロジェクト監査レポート](./PROJECT_AUDIT_REPORT.md)
- [コントリビューションガイド](./CONTRIBUTING.md)
- [Shooter Game README](./shooter_game/README.md)
- [仕様ドキュメント](./specs/)

## CI/CD

このプロジェクトでは GitHub Actions を使用して、以下の自動チェックを実施しています：

- ✅ コードフォーマットチェック
- ✅ コンパイルチェック（警告をエラーとして扱う）
- ✅ テスト実行
- ✅ アセットビルド

詳細は [.github/workflows/ci.yml](./.github/workflows/ci.yml) を参照してください。

## ライセンス

このプロジェクトは学習・テスト目的で作成されています。

## 貢献方法

貢献を歓迎します！詳細は [CONTRIBUTING.md](./CONTRIBUTING.md) を参照してください。

## お問い合わせ

問題や質問がある場合は、[Issue](https://github.com/RyoWakabayashi/spec_kit_test/issues)を作成してください。

---

**Last Updated**: 2025-11-08
