# Data Model: ブラウザシューティングゲーム

**Date**: 2025-10-19  
**Related**: [plan.md](./plan.md), [research.md](./research.md)

## Overview

Phoenix LiveViewで実装するシューティングゲームの全エンティティとゲーム状態の定義。すべてのデータ構造はElixirの不変データ構造として実装され、純粋関数で変換される。

---

## Core Entities

### 1. GameState

ゲーム全体の状態を保持するルートエンティティ。

```elixir
defmodule ShooterGame.Game.State do
  @enforce_keys [:player, :status]
  defstruct [
    :player,              # %Player{}
    enemies: [],          # [%Enemy{}]
    player_bullets: [],   # [%Bullet{}]
    enemy_bullets: [],    # [%Bullet{}]
    score: 0,             # integer
    high_score: 0,        # integer
    status: :start,       # :start | :playing | :game_over
    game_width: 800,      # integer (pixels)
    game_height: 600,     # integer (pixels)
    last_spawn_time: 0,   # monotonic time
    elapsed_time: 0,      # milliseconds since game start
    time_limit: 180_000   # 3 minutes in milliseconds
  ]
  
  @type status :: :start | :playing | :game_over
  
  @type t :: %__MODULE__{
    player: Player.t(),
    enemies: [Enemy.t()],
    player_bullets: [Bullet.t()],
    enemy_bullets: [Bullet.t()],
    score: non_neg_integer(),
    high_score: non_neg_integer(),
    status: status(),
    game_width: pos_integer(),
    game_height: pos_integer(),
    last_spawn_time: integer(),
    elapsed_time: non_neg_integer(),
    time_limit: pos_integer()
  }
end
```

**Fields**:
- `player`: プレイヤーエンティティ（必須）
- `enemies`: 画面上の全敵リスト
- `player_bullets`: プレイヤーが発射した弾リスト
- `enemy_bullets`: 敵が発射した弾リスト
- `score`: 現在のスコア
- `high_score`: ハイスコア（LocalStorageから読み込み）
- `status`: ゲームの状態（開始画面/プレイ中/ゲームオーバー）
- `game_width/height`: ゲーム画面のサイズ
- `last_spawn_time`: 最後に敵が出現した時刻
- `elapsed_time`: ゲーム開始からの経過時間
- `time_limit`: 制限時間

**State Transitions**:
- `:start` → `:playing`: STARTボタンクリック時
- `:playing` → `:game_over`: プレイヤー被弾時または制限時間到達時
- `:game_over` → `:start`: リトライボタンクリック時

**Validation Rules**:
- `score` >= 0
- `elapsed_time` <= `time_limit`
- `player` must exist when `status == :playing`

---

### 2. Player

プレイヤー（自機）エンティティ。

```elixir
defmodule ShooterGame.Game.Player do
  @enforce_keys [:id, :x, :y]
  defstruct [
    :id,                    # string (UUID)
    :x,                     # float (pixels)
    :y,                     # float (pixels)
    width: 40,              # integer (pixels)
    height: 40,             # integer (pixels)
    is_firing: false,       # boolean
    last_fire_time: 0,      # monotonic time
    fire_cooldown_ms: 150   # integer
  ]
  
  @type t :: %__MODULE__{
    id: String.t(),
    x: float(),
    y: float(),
    width: pos_integer(),
    height: pos_integer(),
    is_firing: boolean(),
    last_fire_time: integer(),
    fire_cooldown_ms: pos_integer()
  }
end
```

**Fields**:
- `id`: プレイヤーの一意識別子
- `x, y`: 画面上の位置（左上が原点）
- `width, height`: 当たり判定用のサイズ
- `is_firing`: 現在射撃中かどうか
- `last_fire_time`: 最後に弾を発射した時刻
- `fire_cooldown_ms`: 射撃クールダウン時間

**Validation Rules**:
- `0 <= x <= game_width - width`
- `0 <= y <= game_height - height`
- `fire_cooldown_ms >= 50` (最低限のクールダウン)

---

### 3. Enemy

敵キャラクターエンティティ。

```elixir
defmodule ShooterGame.Game.Enemy do
  @enforce_keys [:id, :x, :y]
  defstruct [
    :id,                    # string (UUID)
    :x,                     # float
    :y,                     # float
    width: 40,              # integer
    height: 40,             # integer
    velocity_x: 0,          # float (pixels per tick)
    velocity_y: 2,          # float (pixels per tick)
    health: 1,              # integer
    score_value: 10,        # integer (points awarded when destroyed)
    last_fire_time: 0,      # monotonic time
    fire_interval_ms: 2000  # integer
  ]
  
  @type t :: %__MODULE__{
    id: String.t(),
    x: float(),
    y: float(),
    width: pos_integer(),
    height: pos_integer(),
    velocity_x: float(),
    velocity_y: float(),
    health: pos_integer(),
    score_value: pos_integer(),
    last_fire_time: integer(),
    fire_interval_ms: pos_integer()
  }
end
```

**Fields**:
- `id`: 敵の一意識別子
- `x, y`: 画面上の位置
- `width, height`: 当たり判定用のサイズ
- `velocity_x, velocity_y`: 移動速度（tick毎の移動量）
- `health`: 体力（1ヒットで破壊の場合は1）
- `score_value`: 撃破時に加算されるスコア
- `last_fire_time`: 最後に弾を発射した時刻
- `fire_interval_ms`: 射撃間隔

**Validation Rules**:
- `health >= 0` (0になった敵は削除)
- `score_value > 0`

---

### 4. Bullet

弾エンティティ（プレイヤーと敵の弾で共用）。

```elixir
defmodule ShooterGame.Game.Bullet do
  @enforce_keys [:id, :x, :y, :velocity_y, :owner_type]
  defstruct [
    :id,            # string (UUID)
    :x,             # float
    :y,             # float
    :velocity_y,    # float (negative = upward, positive = downward)
    :owner_type,    # :player | :enemy
    width: 8,       # integer
    height: 16,     # integer
    damage: 1       # integer
  ]
  
  @type owner_type :: :player | :enemy
  
  @type t :: %__MODULE__{
    id: String.t(),
    x: float(),
    y: float(),
    velocity_y: float(),
    owner_type: owner_type(),
    width: pos_integer(),
    height: pos_integer(),
    damage: pos_integer()
  }
end
```

**Fields**:
- `id`: 弾の一意識別子
- `x, y`: 画面上の位置
- `velocity_y`: 縦方向の速度（負=上、正=下）
- `owner_type`: 発射元の種別（プレイヤーor敵）
- `width, height`: 当たり判定用のサイズ
- `damage`: ダメージ量

**Validation Rules**:
- `velocity_y != 0` (弾は常に移動している)
- 画面外に出た弾は削除される

---

### 5. ScoreRecord

スコア記録エンティティ（LocalStorageに保存）。

```elixir
defmodule ShooterGame.Game.ScoreRecord do
  @enforce_keys [:score, :timestamp]
  defstruct [
    :score,      # integer
    :timestamp   # DateTime
  ]
  
  @type t :: %__MODULE__{
    score: non_neg_integer(),
    timestamp: DateTime.t()
  }
end
```

**Fields**:
- `score`: 記録されたスコア
- `timestamp`: プレイ日時

**Storage**:
- LocalStorageキー: `"shooter_game_high_score"`
- フォーマット: JSON `{"score": 1234, "timestamp": "2025-10-19T12:34:56Z"}`

---

## Relationships

```text
GameState (1)
  ├── Player (1) - ゲーム中は必ず1つ存在
  ├── Enemy (0..N) - 動的に生成・削除
  ├── PlayerBullet (0..N) - プレイヤーが発射
  └── EnemyBullet (0..N) - 敵が発射

Player (1)
  └── generates → PlayerBullet (0..N)

Enemy (1)
  └── generates → EnemyBullet (0..N)

Collision Detection:
  - PlayerBullet × Enemy → Enemy削除、Score加算
  - EnemyBullet × Player → GameOver
```

---

## Pure Function Examples

### State Update Function

```elixir
defmodule ShooterGame.Game do
  @spec update(State.t(), non_neg_integer()) :: State.t()
  def update(%State{status: :playing} = state, delta_ms) do
    state
    |> update_elapsed_time(delta_ms)
    |> check_time_limit()
    |> update_player_bullets()
    |> update_enemy_bullets()
    |> update_enemies()
    |> spawn_enemies()
    |> enemies_fire()
    |> detect_collisions()
    |> remove_offscreen_entities()
  end
  
  def update(state, _delta_ms), do: state
end
```

### Collision Detection Function

```elixir
defmodule ShooterGame.Game.Collision do
  @spec detect_player_bullet_enemy_collisions(State.t()) :: State.t()
  def detect_player_bullet_enemy_collisions(state) do
    {remaining_bullets, remaining_enemies, score_delta} =
      Enum.reduce(state.player_bullets, {[], state.enemies, 0}, fn bullet, {bullets_acc, enemies_acc, score_acc} ->
        case find_collision(bullet, enemies_acc) do
          {:hit, enemy} ->
            # Bullet and enemy both removed, score increased
            updated_enemies = List.delete(enemies_acc, enemy)
            {bullets_acc, updated_enemies, score_acc + enemy.score_value}
          
          :no_hit ->
            # Bullet remains
            {[bullet | bullets_acc], enemies_acc, score_acc}
        end
      end)
    
    %{state | 
      player_bullets: remaining_bullets,
      enemies: remaining_enemies,
      score: state.score + score_delta
    }
  end
end
```

---

## Data Flow

### Client → Server (via LiveView Hooks)

```javascript
// MouseHook pushes events
this.pushEvent("mouse_move", {x: 100, y: 200});
this.pushEvent("mouse_down", {});
this.pushEvent("mouse_up", {});
```

```elixir
# LiveView handles events
def handle_event("mouse_move", %{"x" => x, "y" => y}, socket) do
  socket = update(socket, :game_state, fn state ->
    Player.move_to(state.player, x, y)
  end)
  {:noreply, socket}
end
```

### Server → Client (via PubSub + Hooks)

```elixir
# Server broadcasts game state
Phoenix.PubSub.broadcast(
  ShooterGame.PubSub,
  "game:#{game_id}",
  {:game_state, serialized_state}
)
```

```javascript
// GameHook receives state and renders
this.handleEvent("game_state", (state) => {
  this.renderCanvas(state);
});
```

---

## Summary

- **7つのエンティティ**: GameState, Player, Enemy, Bullet, ScoreRecord
- **不変データ構造**: すべてElixir structとして定義
- **純粋関数**: 状態遷移はすべて純粋関数で実装
- **TypeSpec**: すべてのエンティティに`@type`定義
- **Validation**: 各フィールドに明確な制約
