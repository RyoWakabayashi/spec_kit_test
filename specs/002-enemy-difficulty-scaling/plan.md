# Implementation Plan: 敵難易度の段階的スケーリング

**Branch**: `002-enemy-difficulty-scaling` | **Date**: 2025年10月19日 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-enemy-difficulty-scaling/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

既存のPhoenix LiveViewシューティングゲームに、10秒ごとに段階的に難易度が上昇するシステムを追加します。主要な機能として、敵の弾発射、複雑な移動パターン（直線→ジグザグ→サイン波→円運動）、耐久力の向上、敵数の増加を実装します。技術的アプローチとしては、Elixirの構造体ベースの難易度レベル管理、純粋関数による移動パターン計算、LiveViewのリアルタイム更新機構を活用します。憲法原則（Real-Time First, Functional Game Logic）に準拠し、60fps維持を目標とします。

## Technical Context

**Language/Version**: Elixir 1.15+, Erlang (latest via mise)  
**Primary Dependencies**: Phoenix Framework (LiveView 0.20+), Phoenix PubSub, esbuild (JavaScript bundler)  
**Storage**: ブラウザローカルストレージ（high score保存）、サーバーメモリ（ゲーム状態管理）  
**Testing**: ExUnit（Elixir標準）、Phoenix.LiveViewTest（統合テスト）  
**Target Platform**: モダンブラウザ（WebSocket対応: Chrome 88+, Firefox 85+, Safari 14+）  
**Project Type**: Phoenix Web Application（LiveView + HTML5 Canvas）  
**Performance Goals**: 60fps gameplay, <50ms server response time, <16ms per game tick  
**Constraints**: <100MB memory per client, リアルタイム更新必須、複数ティック処理の遅延なし  
**Scale/Scope**: シングルプレイヤー（現在）、将来的に100+同時プレイヤー対応、最大20体の敵・100発の弾

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Real-Time First**: Architecture supports 60fps real-time updates via Phoenix PubSub
  - ✅ 既存の`:game_tick`メカニズム（16ms間隔）を活用
  - ✅ 難易度更新とパターン計算は全てサーバー側で処理
  - ✅ LiveViewのassign更新で自動的にクライアント同期
  
- [x] **Functional Game Logic**: State transitions are pure functions with immutable data structures
  - ✅ `DifficultyLevel.next_level/1`は純粋関数
  - ✅ `MovementPattern.apply_pattern/4`は純粋関数（副作用なし）
  - ✅ `State.update_difficulty/1`は新しいStateを返すのみ
  - ✅ 全エンティティ（Enemy, DifficultyLevel）はimmutable構造体
  
- [x] **LiveView Component Architecture**: Game elements are properly componentized
  - ✅ 既存のコンポーネント構造を維持（GameLive, GameCanvas JSフック）
  - ✅ 難易度レベル表示は既存UIに統合
  - ✅ Canvas描画は`phx-update="ignore"`で独立
  
- [x] **Performance-First Rendering**: Design targets 60fps with efficient DOM updates
  - ✅ Canvas描画は再レンダリング対象外
  - ✅ 難易度レベル表示のみ更新（最小限のDOM変更）
  - ✅ パターン計算は最大2ms（20敵 × 0.1ms）で60fps予算内
  - ✅ バッチ更新でassignは1ティックあたり1回のみ
  
- [x] **Test-Driven Development**: Test plan covers game mechanics, multiplayer, and performance
  - ✅ Unit tests: DifficultyLevel, MovementPattern, Enemy拡張部分
  - ✅ Integration tests: LiveViewでの難易度上昇シナリオ
  - ✅ Performance tests: ティック処理時間計測（目標<16ms）
  - ✅ Property-based tests（オプション）: ランダムパラメータでの座標範囲保証

**Phase 1 Re-check**: すべての原則に準拠。違反なし。

## Project Structure

### Documentation (this feature)

```
specs/002-enemy-difficulty-scaling/
├── plan.md              # This file (/speckit.plan command output) ✅
├── research.md          # Phase 0 output (/speckit.plan command) ✅
├── data-model.md        # Phase 1 output (/speckit.plan command) ✅
├── quickstart.md        # Phase 1 output (/speckit.plan command) ✅
├── contracts/           # Phase 1 output (/speckit.plan command) ✅
│   └── liveview-events.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root: shooter_game/)

```
shooter_game/
├── lib/
│   ├── shooter_game/
│   │   └── game/
│   │       ├── state.ex              # 既存（拡張: difficulty_level, last_difficulty_update追加）
│   │       ├── enemy.ex              # 既存（拡張: movement_pattern, max_health追加）
│   │       ├── difficulty_level.ex   # 新規作成: 難易度レベル管理
│   │       └── movement_pattern.ex   # 新規作成: 移動パターン計算
│   └── shooter_game_web/
│       └── live/
│           └── game_live.ex          # 既存（拡張: 難易度更新ロジック、レベルアップ通知）
├── test/
│   ├── shooter_game/
│   │   └── game/
│   │       ├── difficulty_level_test.exs  # 新規作成
│   │       ├── movement_pattern_test.exs  # 新規作成
│   │       ├── enemy_test.exs             # 既存（拡張: 難易度対応テスト追加）
│   │       └── state_test.exs             # 既存（拡張: 難易度更新テスト追加）
│   └── shooter_game_web/
│       └── live/
│           └── game_live_test.exs         # 既存（拡張: 統合テスト追加）
└── assets/
    ├── js/
    │   └── hooks/
    │       └── game_canvas.js        # 既存（拡張: レベルアップイベント処理追加）
    └── css/
        └── app.css                   # 既存（拡張: レベルアップ通知スタイル追加）
```

**Structure Decision**: Phoenix Web Applicationアーキテクチャを採用。既存のゲームロジック（`lib/shooter_game/game/`）とLiveView層（`lib/shooter_game_web/live/`）を拡張する形で実装。新規モジュール（DifficultyLevel, MovementPattern）は既存のgameディレクトリ内に配置し、一貫性を保つ。テスト構造も既存の階層に従う。

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

**N/A** - 本機能では憲法違反なし。全ての原則に準拠した設計が完了しています。

