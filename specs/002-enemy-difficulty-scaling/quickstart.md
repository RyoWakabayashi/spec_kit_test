# Quickstart: 敵難易度の段階的スケーリング機能開発

**Feature**: 002-enemy-difficulty-scaling  
**Date**: 2025年10月19日  
**Target Audience**: 開発者（本機能の実装担当者）

## 概要

このガイドは、敵難易度の段階的スケーリング機能を実装するための開発者向けクイックスタートです。既存のPhoenix LiveViewシューティングゲームに10秒ごとに難易度が上昇するシステムを追加します。

## 前提条件

- Elixir 1.15+ および Erlang がインストール済み（mise経由推奨）
- Phoenix Framework の基本知識
- Phoenix LiveView の理解
- 既存のゲームコード（001-browser-shooter-game）が動作している

## プロジェクト構造

```
shooter_game/
├── lib/
│   ├── shooter_game/
│   │   └── game/
│   │       ├── state.ex              # 既存（拡張対象）
│   │       ├── enemy.ex              # 既存（拡張対象）
│   │       ├── difficulty_level.ex   # 新規作成
│   │       └── movement_pattern.ex   # 新規作成
│   └── shooter_game_web/
│       └── live/
│           └── game_live.ex          # 既存（拡張対象）
├── test/
│   ├── shooter_game/
│   │   └── game/
│   │       ├── difficulty_level_test.exs  # 新規作成
│   │       ├── movement_pattern_test.exs  # 新規作成
│   │       └── enemy_test.exs             # 既存（拡張対象）
│   └── shooter_game_web/
│       └── live/
│           └── game_live_test.exs         # 既存（拡張対象）
└── assets/
    └── js/
        └── hooks/
            └── game_canvas.js        # 既存（拡張対象）
```

## 実装ステップ

### Phase 1: コアロジック実装（難易度レベル管理）

#### Step 1.1: `DifficultyLevel` モジュール作成

**ファイル**: `lib/shooter_game/game/difficulty_level.ex`

**目的**: 難易度レベルごとの設定を管理

**実装内容**:
```elixir
defmodule ShooterGame.Game.DifficultyLevel do
  @moduledoc """
  難易度レベルの設定とレベル遷移ロジックを管理
  """
  
  defstruct [
    level: 1,
    spawn_interval_ms: 2000,
    max_enemies: 5,
    enemy_health_multiplier: 1.0,
    fire_interval_ms: 3000,
    movement_patterns: [:linear]
  ]
  
  @type t :: %__MODULE__{
    level: pos_integer(),
    spawn_interval_ms: pos_integer(),
    max_enemies: pos_integer(),
    enemy_health_multiplier: float(),
    fire_interval_ms: pos_integer(),
    movement_patterns: [atom()]
  }
  
  # レベル定義（研究成果に基づく）
  @level_configs %{
    1 => %{spawn_interval_ms: 2000, max_enemies: 5, health_multi: 1.0, 
           fire_interval_ms: 3000, patterns: [:linear]},
    2 => %{spawn_interval_ms: 1800, max_enemies: 7, health_multi: 1.0,
           fire_interval_ms: 2800, patterns: [:linear, :zigzag]},
    3 => %{spawn_interval_ms: 1600, max_enemies: 9, health_multi: 1.5,
           fire_interval_ms: 2600, patterns: [:zigzag, :sine_wave]},
    # ... レベル15まで定義
  }
  
  @doc "新しい難易度レベルを生成"
  def new(level \\ 1), do: get_config(level)
  
  @doc "次のレベルに進める"
  def next_level(%__MODULE__{level: level} = _current) do
    new_level = min(level + 1, 15)  # 最大レベル15
    get_config(new_level)
  end
  
  @doc "レベル番号から設定を取得"
  def get_config(level) when level >= 1 and level <= 15 do
    config = Map.get(@level_configs, level, @level_configs[1])
    %__MODULE__{
      level: level,
      spawn_interval_ms: config.spawn_interval_ms,
      max_enemies: config.max_enemies,
      enemy_health_multiplier: config.health_multi,
      fire_interval_ms: config.fire_interval_ms,
      movement_patterns: config.patterns
    }
  end
end
```

**テスト作成**: `test/shooter_game/game/difficulty_level_test.exs`
```elixir
defmodule ShooterGame.Game.DifficultyLevelTest do
  use ExUnit.Case
  alias ShooterGame.Game.DifficultyLevel
  
  test "new/1 creates level 1 by default" do
    level = DifficultyLevel.new()
    assert level.level == 1
    assert level.max_enemies == 5
  end
  
  test "next_level/1 increments level" do
    level = DifficultyLevel.new(1)
    next = DifficultyLevel.next_level(level)
    assert next.level == 2
    assert next.max_enemies == 7
  end
  
  test "next_level/1 caps at level 15" do
    level = DifficultyLevel.new(15)
    next = DifficultyLevel.next_level(level)
    assert next.level == 15
  end
end
```

**実行確認**:
```bash
cd shooter_game
mix test test/shooter_game/game/difficulty_level_test.exs
```

---

#### Step 1.2: `State` に難易度レベルを統合

**ファイル**: `lib/shooter_game/game/state.ex`

**変更内容**:

1. **defstruct に追加**:
```elixir
defstruct [
  # ... 既存フィールド ...
  difficulty_level: nil,
  last_difficulty_update: 0
]
```

2. **new/1 を修正**:
```elixir
def new(high_score \\ 0) do
  %__MODULE__{
    player: Player.new(400, 500),
    high_score: high_score,
    status: :start,
    difficulty_level: DifficultyLevel.new(1),  # 追加
    last_difficulty_update: 0                   # 追加
  }
end
```

3. **start_game/1 を修正**:
```elixir
def start_game(%__MODULE__{} = state) do
  %{
    state
    | status: :playing,
      score: 0,
      elapsed_time: 0,
      difficulty_level: DifficultyLevel.new(1),  # リセット
      last_difficulty_update: 0,                 # リセット
      last_spawn_time: System.monotonic_time(:millisecond)
  }
end
```

4. **難易度更新関数を追加**:
```elixir
@doc """
経過時間に基づき難易度レベルを更新。
10秒ごとにレベルアップ。
"""
def update_difficulty(%__MODULE__{status: :playing} = state) do
  current_level_duration = state.elapsed_time - state.last_difficulty_update
  
  if current_level_duration >= 10_000 do
    new_difficulty = DifficultyLevel.next_level(state.difficulty_level)
    %{
      state
      | difficulty_level: new_difficulty,
        last_difficulty_update: state.elapsed_time
    }
  else
    state
  end
end

def update_difficulty(state), do: state

@doc "難易度更新が必要かチェック"
def should_increase_difficulty?(%__MODULE__{status: :playing} = state) do
  (state.elapsed_time - state.last_difficulty_update) >= 10_000
end

def should_increase_difficulty?(_state), do: false
```

**テスト追加**: `test/shooter_game/game/state_test.exs`
```elixir
test "update_difficulty increases level every 10 seconds" do
  state = State.new() |> State.start_game()
  
  # 9秒経過 - レベル変わらず
  state = %{state | elapsed_time: 9_000}
  state = State.update_difficulty(state)
  assert state.difficulty_level.level == 1
  
  # 10秒経過 - レベル2へ
  state = %{state | elapsed_time: 10_000}
  state = State.update_difficulty(state)
  assert state.difficulty_level.level == 2
  assert state.last_difficulty_update == 10_000
end
```

---

### Phase 2: 移動パターン実装

#### Step 2.1: `MovementPattern` モジュール作成

**ファイル**: `lib/shooter_game/game/movement_pattern.ex`

**実装内容**:
```elixir
defmodule ShooterGame.Game.MovementPattern do
  @moduledoc """
  敵の移動パターンを計算する純粋関数群
  """
  
  alias ShooterGame.Game.Enemy
  
  @doc "パターンに基づき敵の位置を更新"
  def apply_pattern(enemy, current_time_ms, game_width, game_height) do
    pattern_type = enemy.movement_pattern.pattern_type
    params = enemy.movement_pattern.params
    spawn_time = enemy.movement_pattern.spawn_time
    
    elapsed_since_spawn = current_time_ms - spawn_time
    
    case pattern_type do
      :linear -> apply_linear(enemy)
      :zigzag -> apply_zigzag(enemy, elapsed_since_spawn, params)
      :sine_wave -> apply_sine_wave(enemy, elapsed_since_spawn, params)
      :circular -> apply_circular(enemy, elapsed_since_spawn, params)
      _ -> apply_linear(enemy)  # フォールバック
    end
    |> clamp_to_bounds(game_width, game_height)
  end
  
  # 直線移動（既存の動作）
  defp apply_linear(enemy) do
    %{enemy | x: enemy.x + enemy.velocity_x, y: enemy.y + enemy.velocity_y}
  end
  
  # ジグザグ移動
  defp apply_zigzag(enemy, elapsed_ms, params) do
    amplitude = Map.get(params, :amplitude, 3.0)
    frequency = Map.get(params, :frequency, 500)
    
    x_offset = amplitude * :math.sin(elapsed_ms / frequency)
    %{enemy | x: enemy.x + x_offset, y: enemy.y + enemy.velocity_y}
  end
  
  # サイン波移動
  defp apply_sine_wave(enemy, elapsed_ms, params) do
    amplitude = Map.get(params, :amplitude, 50.0)
    wavelength = Map.get(params, :wavelength, 1000)
    
    # ベースX座標 + サイン波オフセット
    base_x = enemy.x
    x_offset = amplitude * :math.sin(elapsed_ms / wavelength)
    
    %{enemy | x: base_x + x_offset, y: enemy.y + enemy.velocity_y}
  end
  
  # 円運動（実装省略、上記パターンを参考に）
  defp apply_circular(enemy, _elapsed_ms, _params), do: enemy
  
  # 境界チェック
  defp clamp_to_bounds(enemy, width, height) do
    clamped_x = max(0, min(enemy.x, width - enemy.width))
    clamped_y = max(0, min(enemy.y, height - enemy.height))
    %{enemy | x: clamped_x, y: clamped_y}
  end
end
```

**テスト**: `test/shooter_game/game/movement_pattern_test.exs`
```elixir
test "linear pattern moves enemy downward" do
  enemy = %Enemy{x: 100, y: 100, velocity_y: 2, movement_pattern: %{pattern_type: :linear}}
  updated = MovementPattern.apply_pattern(enemy, 0, 800, 600)
  assert updated.y == 102
end
```

---

#### Step 2.2: `Enemy` モジュールを拡張

**ファイル**: `lib/shooter_game/game/enemy.ex`

**変更内容**:

1. **defstruct に追加**:
```elixir
defstruct [
  # ... 既存フィールド ...
  movement_pattern: %{pattern_type: :linear, params: %{}, spawn_time: 0},
  max_health: 1
]
```

2. **難易度対応の生成関数を追加**:
```elixir
@doc "難易度レベルを考慮した敵生成"
def new_with_difficulty(x, y, difficulty_level, pattern_type) do
  base_health = calculate_health(difficulty_level)
  pattern = select_pattern(pattern_type, difficulty_level)
  
  %__MODULE__{
    id: generate_id(),
    x: x,
    y: y,
    health: base_health,
    max_health: base_health,
    movement_pattern: pattern,
    fire_interval_ms: difficulty_level.fire_interval_ms
  }
end

defp calculate_health(difficulty_level) do
  base = 1
  floor(base * difficulty_level.enemy_health_multiplier)
end

defp select_pattern(pattern_type, difficulty_level) do
  spawn_time = System.monotonic_time(:millisecond)
  params = default_params_for(pattern_type)
  
  %{
    pattern_type: pattern_type,
    params: params,
    spawn_time: spawn_time
  }
end

defp default_params_for(:zigzag), do: %{amplitude: 3.0, frequency: 500}
defp default_params_for(:sine_wave), do: %{amplitude: 50.0, wavelength: 1000}
defp default_params_for(_), do: %{}
```

3. **移動更新関数を追加**:
```elixir
@doc "移動パターンに基づいて位置を更新"
def update_movement(enemy, current_time_ms, game_width, game_height) do
  MovementPattern.apply_pattern(enemy, current_time_ms, game_width, game_height)
end
```

---

### Phase 3: LiveView統合

#### Step 3.1: `GameLive` を更新

**ファイル**: `lib/shooter_game_web/live/game_live.ex`

**変更内容**:

1. **render関数にレベル表示を追加**:
```elixir
<div class="game-ui">
  <div class="score">Score: {@game_state.score}</div>
  <div class="high-score">High Score: {@game_state.high_score}</div>
  <div class="difficulty-level">Level: {@game_state.difficulty_level.level}</div>
  <div class="time">Time: {div(@game_state.elapsed_time, 1000)}s</div>
</div>
```

2. **handle_info(:game_tick, ...) を拡張**:
```elixir
def handle_info(:game_tick, socket) do
  state = socket.assigns.game_state
  
  if state.status == :playing do
    previous_level = state.difficulty_level.level
    
    new_state =
      state
      |> State.update_elapsed_time(16)
      |> State.update_difficulty()              # 難易度更新
      |> spawn_enemies_with_difficulty()        # 難易度考慮のスポーン
      |> update_enemies_with_patterns()         # パターン適用
      |> update_bullets()
      |> handle_collisions()
      |> check_game_over()
      |> check_time_limit()
    
    socket = assign(socket, :game_state, new_state)
    
    # レベルアップ通知
    socket = if new_state.difficulty_level.level > previous_level do
      push_event(socket, "difficulty_level_up", %{
        new_level: new_state.difficulty_level.level,
        previous_level: previous_level,
        timestamp: new_state.elapsed_time
      })
    else
      socket
    end
    
    schedule_game_tick()
    {:noreply, socket}
  else
    {:noreply, socket}
  end
end
```

3. **敵スポーン関数を更新**:
```elixir
defp spawn_enemies_with_difficulty(state) do
  current_time = System.monotonic_time(:millisecond)
  time_since_spawn = current_time - state.last_spawn_time
  difficulty = state.difficulty_level
  
  if time_since_spawn >= difficulty.spawn_interval_ms and
     length(state.enemies) < difficulty.max_enemies do
    
    # パターンをランダム選択
    pattern = Enum.random(difficulty.movement_patterns)
    x = :rand.uniform(state.game_width - 40)
    enemy = Enemy.new_with_difficulty(x, -40, difficulty, pattern)
    
    %{state | enemies: [enemy | state.enemies], last_spawn_time: current_time}
  else
    state
  end
end
```

4. **敵移動更新関数を追加**:
```elixir
defp update_enemies_with_patterns(state) do
  current_time = state.elapsed_time
  
  updated_enemies =
    state.enemies
    |> Enum.map(fn enemy ->
      Enemy.update_movement(enemy, current_time, state.game_width, state.game_height)
    end)
    |> Enum.filter(fn enemy -> enemy.y < state.game_height end)
  
  %{state | enemies: updated_enemies}
end
```

---

#### Step 3.2: JavaScript Hook を更新

**ファイル**: `assets/js/hooks/game_canvas.js`

**追加内容**:
```javascript
mounted() {
  // ... 既存のコード ...
  
  // レベルアップイベントハンドラ
  this.handleEvent("difficulty_level_up", ({new_level, previous_level}) => {
    console.log(`Level Up! ${previous_level} → ${new_level}`);
    this.showLevelUpNotification(new_level);
    // 必要に応じて効果音やアニメーション
  });
}

showLevelUpNotification(level) {
  // UI通知の実装（例: 画面中央にテキスト表示）
  const notification = document.createElement('div');
  notification.className = 'level-up-notification';
  notification.textContent = `Level ${level}!`;
  document.body.appendChild(notification);
  
  setTimeout(() => notification.remove(), 2000);
}
```

**CSS追加** (`assets/css/app.css`):
```css
.level-up-notification {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 48px;
  color: #FFD700;
  text-shadow: 2px 2px 4px rgba(0,0,0,0.8);
  animation: fadeInOut 2s ease-in-out;
  pointer-events: none;
  z-index: 1000;
}

@keyframes fadeInOut {
  0%, 100% { opacity: 0; }
  50% { opacity: 1; }
}
```

---

### Phase 4: 統合テスト

#### Step 4.1: LiveView統合テスト

**ファイル**: `test/shooter_game_web/live/game_live_test.exs`

**追加テスト**:
```elixir
test "difficulty level increases every 10 seconds", %{conn: conn} do
  {:ok, view, _html} = live(conn, "/")
  
  # ゲーム開始
  view |> element("button", "START") |> render_click()
  
  # レベル1確認
  assert view |> render() =~ "Level: 1"
  
  # 10秒分のティックをシミュレート (625 ticks)
  for _ <- 1..625 do
    send(view.pid, :game_tick)
    Process.sleep(1)
  end
  
  # レベル2へ上昇確認
  assert view |> render() =~ "Level: 2"
end

test "spawns more enemies at higher difficulty", %{conn: conn} do
  {:ok, view, _html} = live(conn, "/")
  view |> element("button", "START") |> render_click()
  
  # レベル1: max 5 enemies
  initial_state = :sys.get_state(view.pid).assigns.game_state
  assert initial_state.difficulty_level.max_enemies == 5
  
  # レベルアップ後
  for _ <- 1..625, do: send(view.pid, :game_tick)
  
  new_state = :sys.get_state(view.pid).assigns.game_state
  assert new_state.difficulty_level.max_enemies == 7
end
```

---

## 実行とデバッグ

### 開発サーバー起動

```bash
cd shooter_game
mix phx.server
```

ブラウザで `http://localhost:4000` にアクセス

### テスト実行

```bash
# 全テスト
mix test

# 特定モジュールのテスト
mix test test/shooter_game/game/difficulty_level_test.exs

# 統合テスト
mix test test/shooter_game_web/live/game_live_test.exs
```

### デバッグTips

1. **難易度レベル確認**:
   - ブラウザのコンソールで LiveView の assigns を確認
   - `liveSocket.main.el.dataset` で現在のassign値を見る

2. **パフォーマンスチェック**:
   ```elixir
   # game_live.ex の handle_info(:game_tick) 内
   start_time = System.monotonic_time(:microsecond)
   # ... 処理 ...
   duration = System.monotonic_time(:microsecond) - start_time
   if duration > 16_000, do: Logger.warning("Slow tick: #{duration}μs")
   ```

3. **移動パターン可視化**:
   - Canvas描画時に敵の `movement_pattern.pattern_type` を色分け表示
   - `:linear` → 赤、`:zigzag` → 青、`:sine_wave` → 緑 等

---

## トラブルシューティング

### 問題: 難易度が上昇しない

**確認事項**:
- `elapsed_time` が正しく更新されているか
- `update_difficulty/1` が呼ばれているか
- `should_increase_difficulty?/1` の条件ロジック

**デバッグ**:
```elixir
IO.inspect(state.elapsed_time, label: "Elapsed")
IO.inspect(state.last_difficulty_update, label: "Last Update")
```

### 問題: 敵の動きがおかしい

**確認事項**:
- `MovementPattern.apply_pattern/4` の戻り値
- 境界チェック `clamp_to_bounds/3` が機能しているか
- パターンパラメータの妥当性

**デバッグ**:
```elixir
# movement_pattern.ex
def apply_pattern(enemy, current_time_ms, game_width, game_height) do
  result = # ... 計算 ...
  IO.inspect(result, label: "Updated Enemy #{enemy.id}")
  result
end
```

### 問題: フレームレートが低下

**対策**:
- 敵数上限を減らす（`max_enemies` の調整）
- 複雑なパターン（circular, spiral）の使用レベルを上げる
- Telemetryでボトルネック特定

---

## 次のステップ

1. **バランス調整**: `@level_configs` のパラメータを実プレイでチューニング
2. **追加パターン**: `spiral`, `random_walk` 等の実装
3. **ビジュアル強化**: レベルアップアニメーション、パーティクルエフェクト
4. **サウンド**: レベルアップ効果音、難易度別BGM
5. **統計追跡**: 到達レベル、プレイ時間等の記録

---

## 参考資料

- **研究文書**: `specs/002-enemy-difficulty-scaling/research.md`
- **データモデル**: `specs/002-enemy-difficulty-scaling/data-model.md`
- **APIコントラクト**: `specs/002-enemy-difficulty-scaling/contracts/liveview-events.md`
- **Phoenix LiveView公式**: https://hexdocs.pm/phoenix_live_view/

---

## チェックリスト

実装完了の確認:

- [ ] `DifficultyLevel` モジュール実装 + テスト通過
- [ ] `MovementPattern` モジュール実装 + テスト通過
- [ ] `State` 拡張完了 + テスト通過
- [ ] `Enemy` 拡張完了 + テスト通過
- [ ] `GameLive` 統合完了 + 手動テスト成功
- [ ] JSフック更新 + レベルアップ通知動作確認
- [ ] 統合テスト追加 + 全テスト通過
- [ ] パフォーマンステスト（60fps維持）
- [ ] ブラウザでの実機確認（10秒ごとのレベルアップ）
- [ ] コード レビュー完了

完了後、`/speckit.tasks` コマンドで実装タスクを生成してください。
