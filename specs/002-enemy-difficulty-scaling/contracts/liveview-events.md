# LiveView Events Contract

**Feature**: 002-enemy-difficulty-scaling  
**Protocol**: Phoenix LiveView Events  
**Date**: 2025年10月19日

## Overview

本機能で追加・変更されるPhoenix LiveViewイベントとそのペイロード定義。

## Server → Client Events

### 1. Assign Updates (自動送信)

LiveViewのassign機構を通じて自動的にクライアントに送信されるデータ。

#### `@game_state` (既存の拡張)

**Trigger**: ゲームティックごと（16ms間隔）

**Payload Structure**:

```elixir
%{
  # ... 既存フィールド ...
  difficulty_level: %{
    level: integer(),                    # 現在の難易度レベル (1-15)
    spawn_interval_ms: integer(),        # 敵出現間隔
    max_enemies: integer(),              # 最大敵数
    enemy_health_multiplier: float(),    # 耐久力倍率
    fire_interval_ms: integer(),         # 弾発射間隔
    movement_patterns: [atom()]          # 使用可能なパターンリスト
  },
  last_difficulty_update: integer(),     # 最後の更新時刻（elapsed_time基準）
  enemies: [
    %{
      id: string(),
      x: float(),
      y: float(),
      width: integer(),
      height: integer(),
      velocity_x: float(),
      velocity_y: float(),
      health: integer(),                 # 現在の耐久力
      max_health: integer(),             # 最大耐久力（新規）
      movement_pattern: %{                # 移動パターン情報（新規）
        pattern_type: atom(),
        params: map(),
        spawn_time: integer()
      }
    }
  ],
  # ... その他既存フィールド ...
}
```

**Usage**: HEExテンプレートで表示、JSフックでCanvas描画

**Performance Note**: 
- Canvas部分は `phx-update="ignore"` で再描画防止
- 難易度レベル表示のみ再レンダリング対象

### 2. Custom Push Events (明示的送信)

#### `difficulty_level_up`

**Trigger**: 難易度レベルが上昇したとき

**Direction**: Server → Client (via `push_event/3`)

**Payload**:

```elixir
%{
  "new_level" => integer(),              # 新しいレベル番号
  "previous_level" => integer(),         # 前のレベル番号
  "timestamp" => integer()               # イベント発生時刻（elapsed_time）
}
```

**Client Handler**: JSフック `GameCanvas` で受信

**Purpose**: レベルアップ時の視覚効果・音声効果トリガー

**Example**:
```javascript
// assets/js/hooks/game_canvas.js
this.handleEvent("difficulty_level_up", ({new_level, previous_level}) => {
  this.showLevelUpNotification(new_level);
  this.playLevelUpSound();
  // 画面エフェクト等
});
```

## Client → Server Events

### 既存イベント（変更なし）

以下のイベントは既存のまま使用:

- `start_game`: ゲーム開始
- `restart_game`: ゲーム再開
- `mouse_move`: マウス移動（プレイヤー移動）
- `key_down`: キーボード入力（発射）

**Note**: 難易度システムはサーバー側で自動管理されるため、クライアントからの明示的な操作は不要。

## Internal Server Messages

### `:game_tick`

**Type**: `handle_info/2` message

**Frequency**: 16ms間隔（60fps）

**Processing Flow**:

1. 経過時間更新 (`elapsed_time += 16`)
2. **難易度チェック・更新** (新規)
   - `should_increase_difficulty?(state)` 判定
   - 10秒ごとにレベル上昇
   - レベルアップイベント送信
3. 敵スポーン（難易度設定を参照）
4. 敵移動（パターン適用）
5. 弾移動
6. 衝突判定
7. ゲームオーバーチェック
8. State更新・assign

**Code Pattern**:

```elixir
def handle_info(:game_tick, socket) do
  state = socket.assigns.game_state
  
  state
  |> update_elapsed_time(16)
  |> update_difficulty_level()           # 新規処理
  |> spawn_enemies_with_difficulty()     # 難易度考慮
  |> update_enemies_with_patterns()      # パターン適用
  |> update_bullets()
  |> handle_collisions()
  |> check_game_over()
  |> then(fn new_state ->
    socket = assign(socket, :game_state, new_state)
    
    # レベルアップ通知
    socket = if new_state.difficulty_level.level > state.difficulty_level.level do
      push_event(socket, "difficulty_level_up", %{
        new_level: new_state.difficulty_level.level,
        previous_level: state.difficulty_level.level,
        timestamp: new_state.elapsed_time
      })
    else
      socket
    end
    
    {:noreply, socket}
  end)
end
```

## Error Handling

### Server-Side Errors

**Invalid Difficulty Level**:
- **Scenario**: 計算ミスでレベルが範囲外になる
- **Handling**: レベルを1-15の範囲内にクランプ
- **Logging**: `:warning` レベルでログ出力

**Pattern Application Failure**:
- **Scenario**: 移動パターン適用時の例外
- **Handling**: 敵をlinearパターンにフォールバック
- **Logging**: `:error` レベルでスタックトレース記録

**Performance Degradation**:
- **Scenario**: ゲームティック処理が16msを超過
- **Handling**: 敵・弾の上限強制、警告表示
- **Logging**: `:warning` + Telemetryイベント発火

### Client-Side Errors

**Level Up Notification Failure**:
- **Scenario**: JSフックでのエラー
- **Handling**: コンソールエラー出力、ゲーム進行は継続
- **Logging**: `console.error` with event details

**Canvas Rendering Issue**:
- **Scenario**: パターン計算結果が異常値
- **Handling**: 該当敵をスキップして描画継続
- **Logging**: Warning with enemy ID

## Validation Rules

### Server-Side Validation

**Difficulty Level Updates**:
- レベルは単調増加のみ許可
- レベル範囲: 1 <= level <= 15
- 更新間隔: 10秒（±100ms許容）

**Enemy Spawning**:
- 敵数は `difficulty_level.max_enemies` を超えない
- スポーン間隔は `difficulty_level.spawn_interval_ms` 以上
- 移動パターンは `difficulty_level.movement_patterns` 内から選択

**Movement Pattern Application**:
- 計算後の座標はゲーム境界内に補正
- 速度は最大値（10.0 px/tick）を超えない
- NaN/Infinity チェック必須

## Event Sequencing

### Game Start Sequence

```
Client: "start_game" event
  ↓
Server: State.start_game()
  ↓
Server: difficulty_level = DifficultyLevel.new(1)
  ↓
Server: Start game loop (:game_tick)
  ↓
Client: Receive initial @game_state with level 1
```

### Level Up Sequence

```
Server: :game_tick (elapsed_time = 10000ms)
  ↓
Server: update_difficulty_level() detects 10s milestone
  ↓
Server: DifficultyLevel.next_level()
  ↓
Server: Update state with new difficulty_level
  ↓
Server: push_event("difficulty_level_up", ...)
  ↓
Client: JS Hook receives event
  ↓
Client: Show notification + play sound
  ↓
Server: Next tick applies new difficulty settings
```

### Enemy Spawn with Difficulty Sequence

```
Server: :game_tick
  ↓
Server: Check spawn timer + enemy count
  ↓
Server: enemies < difficulty_level.max_enemies?
  ↓
Server: Select pattern from difficulty_level.movement_patterns
  ↓
Server: Enemy.new_with_difficulty(x, y, difficulty_level, pattern)
  ↓
Server: Apply health multiplier
  ↓
Server: Add to state.enemies
  ↓
Client: Render new enemy with pattern
```

## Telemetry Events

### 新規Telemetryイベント

#### `[:shooter_game, :difficulty, :level_up]`

**Emitted**: 難易度レベルが上昇したとき

**Measurements**:
```elixir
%{
  duration_ms: integer(),        # 前回レベルアップからの経過時間
  game_time_ms: integer()        # ゲーム開始からの経過時間
}
```

**Metadata**:
```elixir
%{
  new_level: integer(),
  previous_level: integer(),
  current_enemy_count: integer(),
  current_bullet_count: integer()
}
```

#### `[:shooter_game, :performance, :tick]`

**Emitted**: 各ゲームティック終了時（既存イベントの拡張）

**Additional Metadata**:
```elixir
%{
  # ... 既存メタデータ ...
  difficulty_level: integer(),
  pattern_calc_time_us: integer()  # 移動パターン計算時間
}
```

## Backward Compatibility

### 既存機能への影響

**保証事項**:
- 既存のゲームイベント（start_game, mouse_move等）は変更なし
- 既存のassign構造は拡張のみ（削除・型変更なし）
- 既存のテストコードは全て通過する

**移行戦略**:
- DifficultyLevelはデフォルトでレベル1（既存動作と同等）
- 段階的に新機能を有効化可能（フィーチャーフラグオプション）

## Performance Characteristics

**Event Frequency**:
- `:game_tick`: 60 events/sec (constant)
- `difficulty_level_up`: ~0.1 events/sec (10秒ごと)
- Assign updates: 60 updates/sec (game_state全体)

**Payload Sizes**:
- `@game_state`: ~5-10KB (敵20体、弾100発の場合)
- `difficulty_level_up`: ~50 bytes
- Total bandwidth: ~300-600 KB/sec (既存と同等)

**Processing Times** (target):
- Difficulty update: <0.1ms
- Pattern calculation (20 enemies): ~2ms
- Total tick processing: <16ms (60fps維持)

## Security Considerations

**Client Tampering Prevention**:
- 難易度レベルはサーバー側でのみ管理
- クライアントからの難易度変更リクエストは受け付けない
- スコア計算はサーバー側で実行

**Input Validation**:
- クライアントイベントはすべて既存のもの（変更なし）
- サーバー内部の計算結果は範囲チェック必須

## Testing Contracts

### Unit Test Expectations

**Event Handlers**:
- `handle_info(:game_tick, ...)` は16ms以内に完了
- 難易度更新は10秒ごとに正確に発生
- レベルアップイベントは正しいペイロードで送信

**State Transitions**:
- Level 1 → Level 2 at 10000ms elapsed_time
- Level 15 到達後は維持（16に上昇しない）

### Integration Test Scenarios

**Scenario 1: Normal Level Progression**
```elixir
test "difficulty increases every 10 seconds" do
  {:ok, view, _html} = live(conn, "/game")
  
  # Start game
  view |> element("button", "START") |> render_click()
  
  # Simulate 10 seconds
  for _ <- 1..625 do  # 625 ticks * 16ms = 10000ms
    send(view.pid, :game_tick)
  end
  
  # Check level increased
  assert view |> has_element?("div.difficulty-level", "Level: 2")
end
```

**Scenario 2: Enemy Spawn with Difficulty**
```elixir
test "spawns enemies according to difficulty level" do
  # Level 1: max 5 enemies
  # Level 2: max 7 enemies
  # ... assertions
end
```

## Summary

本契約により定義された内容:

✅ LiveViewイベントの完全な仕様  
✅ サーバー・クライアント間の通信プロトコル  
✅ エラーハンドリング戦略  
✅ パフォーマンス目標値  
✅ テスト可能な契約ポイント

次のファイル: `quickstart.md`（開発者向けクイックスタートガイド）
