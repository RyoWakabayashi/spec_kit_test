# Research: ブラウザシューティングゲーム

**Date**: 2025-10-19  
**Related**: [plan.md](./plan.md), [spec.md](./spec.md)

## Overview

Phoenix LiveViewを用いたリアルタイムシューティングゲームの技術的実現方法について調査。特にJavaScript-Elixir間のリアルタイム通信、ゲームループ実装、レンダリング方式、衝突判定の最適な実装方法を決定する。

---

## Research Task 1: Canvas vs SVG Rendering

### Decision

**Canvas APIを使用**

### Rationale

1. **パフォーマンス**: 60fpsを維持するには、多数のゲームエンティティ（自機、敵複数、弾複数）を毎フレーム再描画する必要がある。CanvasはピクセルベースのImmediate modeレンダリングで、DOM操作が不要なため高速
2. **ゲーム向き**: Canvas APIはゲーム開発の標準的な選択肢で、`requestAnimationFrame`との統合が容易
3. **LiveView統合**: Canvasは単一のDOM要素として扱えるため、LiveViewのdiff計算に影響しない。ゲーム状態の更新とCanvas描画を分離できる

### Alternatives Considered

- **SVG**: DOM要素として各エンティティを表現。LiveViewのコンポーネントモデルと相性が良いが、多数の要素を扱う際のパフォーマンスが劣る。60fps維持が困難
- **HTML+CSS Transforms**: 同様にDOM要素だがSVGより軽量。ただしゲームの複雑なビジュアルエフェクトに制限あり

### Implementation Notes

- Canvas要素を`<canvas phx-hook="GameCanvas">`でLiveViewに配置
- JavaScriptフックでCanvas 2D contextを取得し描画処理を実装
- LiveViewからはゲーム状態（エンティティ配列）をJSON形式でプッシュ

---

## Research Task 2: Game Loop Implementation Strategy

### Decision

**Hybrid approach: Client-side animation loop + Server-side game state management**

### Rationale

1. **60fps維持**: `requestAnimationFrame`をクライアント側で実行し、滑らかな描画を保証
2. **Server authoritative**: ゲームロジック（衝突判定、敵AI、スコア計算）はサーバー側で実行し、クライアントは信頼できない
3. **ネットワーク効率**: サーバーは20-30fps（33-50ms間隔）で状態更新を送信。クライアントは受信した状態を60fpsで補間描画
4. **レイテンシ対策**: マウス移動のような即座のフィードバックが必要な操作は、クライアント側で予測的に描画し、サーバーの確認を待つ

### Alternatives Considered

- **Full server-side tick**: サーバーが60fpsでゲーム状態を送信。ネットワーク帯域とサーバーCPU負荷が高すぎる
- **Full client-side**: クライアントでゲームロジックを実行。チート対策ができず、マルチプレイヤー拡張が困難

### Implementation Notes

```elixir
# Server-side: GenServerで30fps game tick
defmodule ShooterGame.GameServer do
  use GenServer
  
  def handle_info(:tick, state) do
    new_state = ShooterGame.Game.update(state, 33) # 33ms delta
    broadcast_state(new_state)
    Process.send_after(self(), :tick, 33)
    {:noreply, new_state}
  end
end
```

```javascript
// Client-side: requestAnimationFrame for smooth rendering
const GameHook = {
  mounted() {
    this.gameState = null;
    this.animationFrame();
  },
  
  handleEvent("game_state", (state) => {
    this.gameState = state;
  }),
  
  animationFrame() {
    if (this.gameState) {
      this.render(this.gameState);
    }
    requestAnimationFrame(() => this.animationFrame());
  }
}
```

---

## Research Task 3: Collision Detection Approach

### Decision

**Server-side collision detection with AABB (Axis-Aligned Bounding Box)**

### Rationale

1. **シンプルさ**: 2D矩形の重なり判定は高速かつ実装が容易
2. **Functional**: 純粋関数として実装可能。入力として2つのエンティティ、出力としてboolean
3. **パフォーマンス**: O(n*m)の全探索でも、エンティティ数が限定的（敵10体、弾30発程度）なら十分高速
4. **正確性保証**: サーバー側で実行することで、クライアント側の操作や改ざんの影響を受けない

### Alternatives Considered

- **Client-side collision**: レイテンシは低いが、チート可能性あり
- **Spatial partitioning (Quadtree)**: エンティティ数が多い場合に有効だが、このゲームの規模では過剰

### Implementation Notes

```elixir
defmodule ShooterGame.Game.Collision do
  def check_collision(entity1, entity2) do
    x_overlap = entity1.x < entity2.x + entity2.width and
                entity1.x + entity1.width > entity2.x
    
    y_overlap = entity1.y < entity2.y + entity2.height and
                entity1.y + entity1.height > entity2.y
    
    x_overlap and y_overlap
  end
  
  def detect_bullet_enemy_collisions(bullets, enemies) do
    for bullet <- bullets,
        enemy <- enemies,
        check_collision(bullet, enemy),
        do: {bullet.id, enemy.id}
  end
end
```

---

## Research Task 4: Enemy Spawning and AI Patterns

### Decision

**Simple spawning system with weighted random timing + Straight-line movement patterns**

### Rationale

1. **MVP適切**: 初期バージョンでは複雑なAI不要。プレイ体験の基本を確立することが優先
2. **Functional design**: スポーンロジックを純粋関数として実装可能。現在時刻とランダムシードを入力とする
3. **拡張性**: 後でパターンを追加しやすい設計（パターンのリストを定義し、ランダムに選択）

### Alternatives Considered

- **Complex AI (pathfinding, formation)**: 初期バージョンには過剰
- **Fixed spawn patterns**: プレイの予測可能性が高すぎてつまらない

### Implementation Notes

```elixir
defmodule ShooterGame.Game.Spawner do
  @spawn_interval_ms 2000  # 2秒ごとに敵出現判定
  
  def should_spawn?(state) do
    time_since_last_spawn = System.monotonic_time(:millisecond) - state.last_spawn_time
    time_since_last_spawn >= @spawn_interval_ms
  end
  
  def spawn_enemy(state) do
    x = :rand.uniform(state.game_width - 50)  # ランダムなX位置
    enemy = %Enemy{
      id: generate_id(),
      x: x,
      y: 0,  # 画面上部から出現
      velocity_x: 0,
      velocity_y: 2,  # 下方向に移動
      width: 40,
      height: 40
    }
    
    %{state | enemies: [enemy | state.enemies]}
  end
end
```

**Movement patterns for future extension**:
- Straight down (initial)
- Sine wave horizontal movement
- Zigzag pattern
- Circular motion

---

## Research Task 5: Bullet Firing Rate Limiting

### Decision

**Server-side cooldown mechanism (150ms minimum interval between bullets)**

### Rationale

1. **Balance**: 無制限の射撃を防ぎ、ゲームバランスを保つ
2. **Performance**: 弾の数を制限することで、衝突判定の計算量を抑える
3. **Cheat prevention**: クライアント側で連打してもサーバーが制御

### Alternatives Considered

- **Client-side only limiting**: 改ざん可能性あり
- **Fixed bullets per second**: 柔軟性に欠ける

### Implementation Notes

```elixir
defmodule ShooterGame.Game.Player do
  @bullet_cooldown_ms 150
  
  def fire_bullet(player, current_time) do
    if can_fire?(player, current_time) do
      bullet = %Bullet{
        x: player.x + player.width / 2,
        y: player.y,
        velocity_y: -5  # 上方向に移動
      }
      
      updated_player = %{player | last_fire_time: current_time}
      {:ok, bullet, updated_player}
    else
      {:cooldown, player}
    end
  end
  
  defp can_fire?(player, current_time) do
    current_time - player.last_fire_time >= @bullet_cooldown_ms
  end
end
```

---

## Research Task 6: LiveView Hooks Best Practices

### Decision

**Separate hooks by responsibility: MouseHook, GameHook, StorageHook**

### Rationale

1. **Separation of concerns**: 各フックが単一の責任を持つ
2. **Testability**: 個別にテスト可能
3. **Reusability**: 他のLiveViewでも再利用可能

### Implementation Pattern

```javascript
// assets/js/hooks/mouse_hook.js
export const MouseHook = {
  mounted() {
    this.handleMouseMove = (e) => {
      const rect = this.el.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      
      this.pushEvent("mouse_move", {x, y});
    };
    
    this.el.addEventListener("mousemove", this.handleMouseMove);
    this.el.addEventListener("mousedown", () => {
      this.pushEvent("mouse_down", {});
    });
    this.el.addEventListener("mouseup", () => {
      this.pushEvent("mouse_up", {});
    });
  },
  
  destroyed() {
    this.el.removeEventListener("mousemove", this.handleMouseMove);
  }
};

// assets/js/hooks/storage_hook.js
export const StorageHook = {
  mounted() {
    this.handleEvent("save_score", ({score}) => {
      const highScore = localStorage.getItem("highScore") || 0;
      if (score > highScore) {
        localStorage.setItem("highScore", score);
        this.pushEvent("high_score_updated", {highScore: score});
      }
    });
    
    // Load high score on mount
    const highScore = localStorage.getItem("highScore") || 0;
    this.pushEvent("high_score_loaded", {highScore: parseInt(highScore)});
  }
};

// assets/js/app.js
import {MouseHook} from "./hooks/mouse_hook";
import {GameHook} from "./hooks/game_hook";
import {StorageHook} from "./hooks/storage_hook";

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: {Mouse: MouseHook, Game: GameHook, Storage: StorageHook},
  params: {_csrf_token: csrfToken}
});
```

---

## Summary of Technical Decisions

| Aspect | Decision | Key Benefit |
|--------|----------|-------------|
| Rendering | Canvas API | 60fps performance |
| Game Loop | Hybrid (client RAF + server tick) | Smooth visuals + authoritative logic |
| Collision | Server-side AABB | Security + simplicity |
| Enemy AI | Random spawn + straight movement | MVP-appropriate |
| Fire Rate | Server cooldown (150ms) | Balance + cheat prevention |
| JS-Elixir | Separate Hooks by concern | Maintainability |

---

## Technology Stack Confirmation

- **mise**: Elixir/Erlang version management (`mise install elixir erlang`)
- **Phoenix**: 1.7+ (latest stable)
- **LiveView**: 0.20+ (included in Phoenix 1.7)
- **esbuild**: JavaScript bundling (Phoenix default)
- **No Ecto**: `mix phx.new shooter_game --no-ecto`

---

## Next Steps (Phase 1)

1. Create `data-model.md` defining all game entities
2. Define contracts for LiveView events (mouse_move, mouse_down, game_state, etc.)
3. Generate `quickstart.md` with mise setup and development workflow
4. Update agent context with Phoenix LiveView specifics
