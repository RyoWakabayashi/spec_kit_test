# Quickstart: ブラウザシューティングゲーム

**Date**: 2025-10-19  
**Related**: [plan.md](./plan.md), [data-model.md](./data-model.md)

## Overview

mise経由でElixir/Erlangをインストールし、Phoenix LiveViewでシューティングゲームを開発するためのセットアップガイド。

---

## Prerequisites

- macOS (既にインストール済み)
- Homebrew (miseのインストールに使用)
- Git
- Modern browser (Chrome 88+, Firefox 85+, Safari 14+)

---

## Step 1: Install mise

miseは複数のプログラミング言語のバージョン管理ツールです。

```bash
# Homebrewでmiseをインストール
brew install mise

# シェル設定にmiseを追加（zsh）
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
source ~/.zshrc

# インストール確認
mise --version
```

---

## Step 2: Install Elixir and Erlang

```bash
# プロジェクトディレクトリに移動
cd /Users/rwakabay/dev/elixir/speck_kit_test/speck_kit_test

# 最新版のElixirとErlangをインストール
mise install elixir@latest erlang@latest

# ローカルで使用するバージョンを設定
mise use elixir@latest erlang@latest

# インストール確認
elixir --version
# Expected output:
# Erlang/OTP 27 [erts-15.x] ...
# Elixir 1.17.x ...
```

`.mise.toml`ファイルが自動生成されます：

```toml
[tools]
elixir = "latest"
erlang = "latest"
```

---

## Step 3: Install Hex and Phoenix

```bash
# Hexパッケージマネージャーをインストール
mix local.hex --force

# Phoenix installerをインストール
mix archive.install hex phx_new --force
```

---

## Step 4: Create Phoenix Project (--no-ecto)

```bash
# プロジェクトを作成（DBなし）
mix phx.new shooter_game --no-ecto

# プロジェクトディレクトリに移動
cd shooter_game

# 依存関係をインストール
mix deps.get

# Node.jsパッケージをインストール（assets用）
cd assets && npm install && cd ..
```

**プロジェクト構造確認**:

```bash
tree -L 2 -I 'node_modules|_build|deps'
# shooter_game/
# ├── lib/
# │   ├── shooter_game/
# │   └── shooter_game_web/
# ├── test/
# ├── assets/
# │   ├── js/
# │   └── css/
# ├── config/
# └── mix.exs
```

---

## Step 5: Verify Setup

```bash
# 開発サーバーを起動
mix phx.server

# または iex モードで起動
iex -S mix phx.server
```

ブラウザで http://localhost:4000 を開き、Phoenix welcome画面が表示されることを確認。

---

## Step 6: Setup Game Project Structure

```bash
# ゲームロジック用ディレクトリを作成
mkdir -p lib/shooter_game/game

# LiveView components用ディレクトリを作成
mkdir -p lib/shooter_game_web/live/components

# JavaScript hooks用ディレクトリを作成
mkdir -p assets/js/hooks

# テスト用ディレクトリを作成
mkdir -p test/shooter_game/game
mkdir -p test/shooter_game_web/live
```

---

## Step 7: Run Tests

```bash
# すべてのテストを実行
mix test

# 特定のテストファイルを実行
mix test test/shooter_game/game/collision_test.exs

# カバレッジ付きで実行
mix test --cover
```

---

## Development Workflow

### 1. Start Development Server

```bash
# 通常起動（ログ出力あり）
mix phx.server

# iex モードで起動（デバッグに便利）
iex -S mix phx.server
```

**Port**: http://localhost:4000

### 2. File Watching

Phoenix LiveViewは自動でファイルの変更を検知してリロードします：

- Elixirファイル: ホットリロード
- CSSファイル: 自動リロード
- JavaScriptファイル: esbuildが自動ビルド

### 3. Interactive Shell (iex)

```bash
iex -S mix phx.server
```

```elixir
# モジュールをリコンパイル
recompile()

# ゲーム状態を手動でテスト
alias ShooterGame.Game.State
state = State.new()
IO.inspect(state)
```

### 4. Code Formatting

```bash
# コードフォーマット
mix format

# フォーマットチェック（CI用）
mix format --check-formatted
```

---

## Project-Specific Commands

### Run Game Logic Tests

```bash
# ゲームロジックの単体テストのみ実行
mix test test/shooter_game/game/

# 特定のモジュールをテスト
mix test test/shooter_game/game/collision_test.exs
```

### Run LiveView Integration Tests

```bash
# LiveViewの統合テスト
mix test test/shooter_game_web/live/
```

### Performance Profiling

```elixir
# iex内でプロファイリング
:fprof.apply(ShooterGame.Game, :update, [state, 33])
:fprof.profile()
:fprof.analyse()
```

---

## Troubleshooting

### mise not found after installation

```bash
# シェルを再起動
exec $SHELL

# または手動でactivate
eval "$(mise activate zsh)"
```

### Elixir version mismatch

```bash
# 現在のバージョン確認
mise current

# 特定バージョンをインストール
mise install elixir@1.17.2 erlang@27.0

# 使用バージョンを切り替え
mise use elixir@1.17.2 erlang@27.0
```

### Phoenix server won't start

```bash
# 依存関係を再インストール
mix deps.clean --all
mix deps.get

# ポートが使用中の場合
lsof -i :4000
# プロセスを終了して再起動
```

### JavaScript not loading

```bash
# Node modulesを再インストール
cd assets
rm -rf node_modules package-lock.json
npm install
cd ..

# esbuildを手動実行
mix assets.deploy
```

---

## Environment Configuration

### Development (.env or config/dev.exs)

```elixir
# config/dev.exs
config :shooter_game, ShooterGameWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]
```

### Test (config/test.exs)

```elixir
# config/test.exs
config :shooter_game, ShooterGameWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warning
```

---

## Next Steps

1. ✅ Setup complete - mise, Elixir, Erlang, Phoenix installed
2. ⏭️ Implement game entities (`lib/shooter_game/game/`)
3. ⏭️ Create LiveView components (`lib/shooter_game_web/live/`)
4. ⏭️ Implement JavaScript hooks (`assets/js/hooks/`)
5. ⏭️ Write tests (`test/`)

---

## Useful Links

- [mise Documentation](https://mise.jdx.dev/)
- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix LiveView Guide](https://hexdocs.pm/phoenix_live_view/)
- [Elixir Lang](https://elixir-lang.org/)
- [Erlang Documentation](https://www.erlang.org/docs)

---

## Quick Reference

```bash
# Common commands
mix phx.server          # Start server
mix test                # Run tests
mix format              # Format code
iex -S mix phx.server   # Interactive shell with server
mix deps.get            # Install dependencies
mix compile             # Compile project

# mise commands
mise install elixir@latest erlang@latest
mise use elixir@latest erlang@latest
mise current            # Show current versions
mise ls                 # List available versions
```
