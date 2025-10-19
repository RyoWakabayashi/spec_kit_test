# Research: 敵難易度の段階的スケーリング

**Feature**: 002-enemy-difficulty-scaling  
**Date**: 2025年10月19日  
**Status**: Complete

## Overview

本機能は既存のPhoenix LiveViewベースのシューティングゲームに、時間経過による段階的な難易度上昇システムを追加します。敵の弾発射、複雑な移動パターン、耐久力の向上、敵数の増加を10秒ごとに段階的に実装します。

## Technical Context Analysis

### Current Implementation

既存のコードベースから以下の技術スタックと実装パターンが確認されました:

**Language/Version**: Elixir 1.15+ (mise経由), Erlang (mise経由)  
**Primary Dependencies**: Phoenix Framework (LiveView), Phoenix PubSub, esbuild  
**Storage**: ブラウザローカルストレージ (high score), サーバーメモリ (game state)  
**Testing**: ExUnit (標準のElixirテストフレームワーク)  
**Target Platform**: モダンブラウザ (WebSocket対応)  
**Project Type**: Phoenix Web Application (LiveView + Canvas rendering)  
**Performance Goals**: 60fps gameplay, <50ms server response time  
**Constraints**: <100MB memory per client, リアルタイム更新必須  
**Scale/Scope**: 現在シングルプレイヤー、将来的に100+同時プレイヤー対応

### Existing Game Architecture

1. **State Management**: `ShooterGame.Game.State` モジュールが全ゲーム状態を保持
   - 純粋関数による状態遷移（Constitution原則II準拠）
   - Immutableデータ構造使用
   - 既存フィールド: player, enemies, player_bullets, enemy_bullets, score, elapsed_time

2. **Enemy System**: `ShooterGame.Game.Enemy` モジュール
   - 既に弾発射機能実装済み (`can_fire?/1`, `fire_bullet/1`)
   - 移動: 単純な velocity_x, velocity_y ベース
   - 耐久力: health フィールド存在
   - スポーン: `ShooterGame.Game.EnemySpawner` で管理

3. **Game Loop**: `ShooterGameWeb.GameLive` LiveView
   - `handle_info(:game_tick, ...)` でメインループ実行
   - 16ms間隔でティック（60fps相当）
   - Phoenix PubSub使用でリアルタイム更新

## Research Findings

### R1: 難易度レベルシステムの実装パターン

**Decision**: `DifficultyLevel` 構造体を新規作成し、`State` に統合

**Rationale**:
- Elixirの構造体により型安全な難易度設定管理
- 各レベルで敵出現数、移動パターン、耐久力倍率、発射間隔を定義
- 10秒タイマーは既存の `elapsed_time` を活用可能

**Implementation Pattern**:
```elixir
defmodule ShooterGame.Game.DifficultyLevel do
  defstruct [
    level: 1,
    spawn_rate: 1000,        # ms between spawns
    max_enemies: 5,
    enemy_health_multiplier: 1.0,
    fire_interval_ms: 2000,
    movement_patterns: [:linear]
  ]
end
```

**Alternatives Considered**:
- ハードコードされた条件分岐 → 保守性が低い
- 外部設定ファイル → オーバーエンジニアリング（現段階では不要）

### R2: 敵の複雑な移動パターン実装

**Decision**: パターンベースの移動システム（関数ポインタとパラメータ）

**Rationale**:
- Elixirの関数型プログラミングを活用
- 各パターンを純粋関数として実装 → テスタビリティ向上
- パターン追加が容易（Open/Closed Principle）

**Movement Patterns**:

1. **Linear (Level 1)**: 既存実装
   - 固定 velocity_x, velocity_y
   
2. **Zigzag (Level 2-3)**:
   - X軸方向に周期的な方向転換
   - パラメータ: amplitude, frequency
   
3. **Sine Wave (Level 3-4)**:
   - Y軸移動 + X軸にサイン波
   - パラメータ: amplitude, wavelength
   
4. **Circular (Level 4-5)**:
   - 中心点周りの円運動
   - パラメータ: center_x, center_y, radius, angular_velocity

5. **Complex Combined (Level 5+)**:
   - 複数パターンの組み合わせ
   - ランダム性追加

**Implementation Approach**:
```elixir
defmodule ShooterGame.Game.MovementPattern do
  def apply_pattern(enemy, :linear, _params, _time), do: Enemy.move(enemy)
  
  def apply_pattern(enemy, :zigzag, params, time) do
    # 時間ベースのX方向変化計算
    new_vx = params.amplitude * :math.sin(time / params.frequency)
    %{enemy | velocity_x: new_vx} |> Enemy.move()
  end
  
  def apply_pattern(enemy, :sine_wave, params, time) do
    x_offset = params.amplitude * :math.sin(time / params.wavelength)
    %{enemy | x: enemy.x + x_offset, y: enemy.y + enemy.velocity_y}
  end
end
```

**Best Practices from Research**:
- 時間（elapsed_time）を基準にした計算 → フレームレート非依存
- パラメータの外部化 → バランス調整が容易
- 境界チェック必須 → 画面外への移動防止

**Alternatives Considered**:
- Behavior Tree → 複雑すぎる（シンプルなパターンには不要）
- Physics Engine → オーバーヘッド大、リアルタイム性能への影響

### R3: 段階的難易度上昇のバランス設計

**Decision**: 指数関数的スケーリングではなく段階的線形スケーリング

**Rationale**:
- プレイヤー適応時間の確保
- 急激な難易度上昇はフラストレーションを生む
- 初心者から上級者まで楽しめる曲線

**Scaling Parameters**:

| Level | Time(s) | Max Enemies | Spawn Rate(ms) | Health Multi | Fire Interval(ms) | Patterns |
|-------|---------|-------------|----------------|--------------|-------------------|----------|
| 1 | 0-10 | 5 | 2000 | 1.0 | 3000 | Linear |
| 2 | 10-20 | 7 | 1800 | 1.0 | 2800 | Linear, Zigzag |
| 3 | 20-30 | 9 | 1600 | 1.5 | 2600 | Zigzag, Sine |
| 4 | 30-40 | 11 | 1400 | 2.0 | 2400 | Sine, Circular |
| 5 | 40-50 | 13 | 1200 | 2.5 | 2200 | All + Combined |
| 6+ | 50+ | +2/level | -100ms | +0.5 | -200ms | Random Complex |

**Performance Safeguards**:
- 敵の絶対上限: 20体（メモリ/CPU保護）
- 弾の絶対上限: 100発
- レベル上限: 15（バランス崩壊防止）

**Research Sources**:
- "Game Feel" by Steve Swink - 難易度曲線設計理論
- Phoenix LiveView Performance Guide - 60fps維持のベストプラクティス
- Elixir パターンマッチング最適化手法

### R4: Phoenix LiveView での高頻度状態更新最適化

**Decision**: 差分更新とバッチ処理の組み合わせ

**Rationale**:
- LiveViewの強み（差分DOM更新）を活用
- 不要な再レンダリングを最小化
- `phx-update="ignore"` でCanvas部分は除外済み

**Optimization Techniques**:

1. **State Batching**:
   - ゲームティック内で全状態変更を集約
   - 1ティックあたり1回の assign 更新

2. **Selective Assigns**:
   - UI表示用の最小限データのみをassignに含める
   - Canvas描画データはJSフック経由で直接送信

3. **Component Isolation**:
   - 難易度レベル表示を独立コンポーネント化
   - `phx-update="ignore"` 活用で不要更新防止

**Implementation Pattern**:
```elixir
def handle_info(:game_tick, socket) do
  state = socket.assigns.game_state
  
  state
  |> update_difficulty_level()
  |> spawn_enemies()
  |> update_enemies()
  |> handle_collisions()
  |> check_game_over()
  |> then(fn new_state ->
    # 1回だけassign更新
    {:noreply, assign(socket, :game_state, new_state)}
  end)
end
```

**Best Practices**:
- 重い計算はバックグラウンドTask使用（必要に応じて）
- `:telemetry` でパフォーマンス計測
- デバッグモードでフレームタイム表示

### R5: テスト戦略

**Decision**: 3層テストアプローチ（Unit, Integration, Performance）

**Unit Tests**:
- `DifficultyLevel` の段階遷移ロジック
- 各移動パターンの数学的正確性
- 耐久力・発射間隔スケーリング計算

**Integration Tests**:
- LiveViewTest で難易度上昇シナリオ
- 敵弾発射と衝突判定
- ゲームオーバー条件

**Performance Tests**:
- `:timer.tc/1` で各ティック処理時間計測
- 目標: <16ms (60fps維持)
- 負荷テスト: 最大敵数・弾数での動作確認

**Test Files Structure**:
```
test/shooter_game/game/
├── difficulty_level_test.exs
├── movement_pattern_test.exs
└── enemy_test.exs (既存に追加)

test/shooter_game_web/live/
└── game_live_test.exs (既存に追加)
```

## Technology Decisions Summary

| Aspect | Technology/Approach | Justification |
|--------|---------------------|---------------|
| 難易度管理 | Struct-based configuration | 型安全、保守性、拡張性 |
| 移動パターン | Function-based patterns | テスタビリティ、純粋関数主義 |
| スケーリング | Linear staged scaling | プレイヤー体験重視 |
| 最適化 | Batch updates + selective assigns | LiveView性能最大化 |
| テスト | 3-tier testing (Unit/Int/Perf) | 品質保証 |

## Open Questions & Resolutions

**Q1: ゲーム一時停止中のタイマー処理**  
**A1**: `status` が `:paused` の場合は `elapsed_time` 更新を停止。仕様書の想定通り。

**Q2: 難易度レベルの永続化**  
**A2**: 不要。セッション内でのみ有効。ハイスコアは既存機能で保存済み。

**Q3: マルチプレイヤーでの難易度同期**  
**A3**: 将来機能。現時点ではシングルプレイヤーのみ対応。サーバー側で統一レベル管理可能。

**Q4: 難易度上昇時のビジュアルフィードバック**  
**A4**: UI通知 + 効果音。LiveViewイベント経由でJSフックに通知、アニメーション実行。

## Performance Impact Assessment

**Expected Changes**:
- 追加計算: 移動パターン計算（敵1体あたり <0.1ms）
- メモリ増加: DifficultyLevel struct (~200 bytes), 移動パターンパラメータ
- ネットワーク: 難易度レベル表示の追加送信（negligible）

**Mitigation Strategies**:
- 敵数上限強制（20体）
- 複雑パターンは高レベルのみ
- プロファイリングで継続監視

**Target Confirmation**: 60fps維持可能と判断

## Implementation Readiness

すべての技術的不明点を解決しました:

✅ 難易度レベルシステムの実装方法明確化  
✅ 移動パターンの技術的アプローチ決定  
✅ パフォーマンス最適化戦略確立  
✅ テスト戦略策定完了  
✅ バランス調整の初期パラメータ定義

**Phase 1（デザイン & コントラクト）への準備完了**
