# LiveView Events Contract

**Date**: 2025-10-19  
**Related**: [data-model.md](../data-model.md)

## Overview

Phoenix LiveView間のイベント通信契約定義。すべてのイベントはクライアント（JavaScript Hooks）とサーバー（LiveView）間でやり取りされる。

---

## Client → Server Events

クライアント側のHooksからサーバー側のLiveViewへ送信されるイベント。

### 1. `mouse_move`

マウスが移動した時にプレイヤーの位置を更新する。

**Payload**:

```typescript
{
  x: number,  // Canvas上のX座標 (0 ~ game_width)
  y: number   // Canvas上のY座標 (0 ~ game_height)
}
```

**Example**:

```javascript
this.pushEvent("mouse_move", {x: 400, y: 300});
```

**Server Handler**:

```elixir
def handle_event("mouse_move", %{"x" => x, "y" => y}, socket) do
  socket = update(socket, :game_state, fn state ->
    Player.move_to(state, x, y)
  end)
  {:noreply, socket}
end
```

**Constraints**:
- `0 <= x <= game_width`
- `0 <= y <= game_height`
- High-frequency event (60fps potential), consider throttling

---

### 2. `mouse_down`

マウスボタンが押された時に射撃を開始する。

**Payload**:

```typescript
{}  // Empty payload
```

**Example**:

```javascript
this.pushEvent("mouse_down", {});
```

**Server Handler**:

```elixir
def handle_event("mouse_down", _params, socket) do
  socket = update(socket, :game_state, fn state ->
    Player.start_firing(state)
  end)
  {:noreply, socket}
end
```

---

### 3. `mouse_up`

マウスボタンが離された時に射撃を停止する。

**Payload**:

```typescript
{}  // Empty payload
```

**Example**:

```javascript
this.pushEvent("mouse_up", {});
```

**Server Handler**:

```elixir
def handle_event("mouse_up", _params, socket) do
  socket = update(socket, :game_state, fn state ->
    Player.stop_firing(state)
  end)
  {:noreply, socket}
end
```

---

### 4. `start_game`

STARTボタンクリック時にゲームを開始する。

**Payload**:

```typescript
{}  // Empty payload
```

**Example**:

```javascript
this.pushEvent("start_game", {});
```

**Server Handler**:

```elixir
def handle_event("start_game", _params, socket) do
  socket = 
    socket
    |> assign(:game_state, GameState.new())
    |> start_game_loop()
  
  {:noreply, socket}
end
```

---

### 5. `restart_game`

ゲームオーバー後のリトライボタンクリック時。

**Payload**:

```typescript
{}  // Empty payload
```

**Example**:

```javascript
this.pushEvent("restart_game", {});
```

**Server Handler**:

```elixir
def handle_event("restart_game", _params, socket) do
  socket = assign(socket, :game_state, GameState.new(socket.assigns.high_score))
  {:noreply, socket}
end
```

---

### 6. `high_score_loaded`

クライアントがLocalStorageからハイスコアを読み込んだ時。

**Payload**:

```typescript
{
  highScore: number  // LocalStorageから読み込んだハイスコア
}
```

**Example**:

```javascript
const highScore = localStorage.getItem("shooter_game_high_score") || 0;
this.pushEvent("high_score_loaded", {highScore: parseInt(highScore)});
```

**Server Handler**:

```elixir
def handle_event("high_score_loaded", %{"highScore" => score}, socket) do
  socket = update(socket, :game_state, fn state ->
    %{state | high_score: score}
  end)
  {:noreply, socket}
end
```

---

## Server → Client Events

サーバー側のLiveViewからクライアント側のHooksへ送信されるイベント。

### 1. `game_state`

ゲーム状態の更新をクライアントに送信する（30fps）。

**Payload**:

```typescript
{
  player: {
    id: string,
    x: number,
    y: number,
    width: number,
    height: number
  },
  enemies: Array<{
    id: string,
    x: number,
    y: number,
    width: number,
    height: number
  }>,
  playerBullets: Array<{
    id: string,
    x: number,
    y: number,
    width: number,
    height: number
  }>,
  enemyBullets: Array<{
    id: string,
    x: number,
    y: number,
    width: number,
    height: number
  }>,
  score: number,
  elapsedTime: number,
  timeLimit: number,
  status: "start" | "playing" | "game_over"
}
```

**Example (Server)**:

```elixir
push_event(socket, "game_state", %{
  player: serialize_player(state.player),
  enemies: Enum.map(state.enemies, &serialize_enemy/1),
  playerBullets: Enum.map(state.player_bullets, &serialize_bullet/1),
  enemyBullets: Enum.map(state.enemy_bullets, &serialize_bullet/1),
  score: state.score,
  elapsedTime: state.elapsed_time,
  timeLimit: state.time_limit,
  status: state.status
})
```

**Client Handler**:

```javascript
this.handleEvent("game_state", (state) => {
  this.gameState = state;
  // State will be rendered on next requestAnimationFrame
});
```

**Frequency**: ~30fps (every 33ms) during gameplay

---

### 2. `save_score`

ゲーム終了時にスコアをLocalStorageに保存するよう指示。

**Payload**:

```typescript
{
  score: number,
  timestamp: string  // ISO 8601 format
}
```

**Example (Server)**:

```elixir
push_event(socket, "save_score", %{
  score: state.score,
  timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
})
```

**Client Handler**:

```javascript
this.handleEvent("save_score", ({score, timestamp}) => {
  const currentHigh = parseInt(localStorage.getItem("shooter_game_high_score") || "0");
  if (score > currentHigh) {
    localStorage.setItem("shooter_game_high_score", score.toString());
    localStorage.setItem("shooter_game_high_score_date", timestamp);
  }
});
```

---

## Event Flow Diagram

```text
[Client: Browser]                    [Server: LiveView]
       |                                     |
       | --- mouse_move {x, y} ------------> |
       |                                     | (update player position)
       |                                     |
       | --- mouse_down {} ----------------> |
       |                                     | (start firing)
       |                                     |
       | <-- game_state {...} -------------- |
       | (render at 60fps)                   | (broadcast at 30fps)
       |                                     |
       | --- mouse_up {} ------------------> |
       |                                     | (stop firing)
       |                                     |
       |                                     | (game over detected)
       | <-- save_score {score, ts} -------- |
       |                                     |
       | (save to LocalStorage)              |
       |                                     |
       | --- high_score_loaded {score} ----> |
       |                                     |
```

---

## Error Handling

### Client-Side Validation

```javascript
// MouseHook
handleMouseMove(e) {
  const rect = this.el.getBoundingClientRect();
  let x = e.clientX - rect.left;
  let y = e.clientY - rect.top;
  
  // Clamp to canvas bounds
  x = Math.max(0, Math.min(x, this.gameWidth));
  y = Math.max(0, Math.min(y, this.gameHeight));
  
  this.pushEvent("mouse_move", {x, y});
}
```

### Server-Side Validation

```elixir
def handle_event("mouse_move", params, socket) do
  with {:ok, x} <- validate_coordinate(params["x"], 0, socket.assigns.game_state.game_width),
       {:ok, y} <- validate_coordinate(params["y"], 0, socket.assigns.game_state.game_height) do
    # Process valid event
  else
    _ ->
      # Ignore invalid event
      {:noreply, socket}
  end
end
```

---

## Performance Considerations

### Throttling High-Frequency Events

```javascript
// MouseHook with throttling
mounted() {
  this.lastMouseMoveTime = 0;
  this.mouseMoveThrottle = 16;  // ~60fps
  
  this.handleMouseMove = (e) => {
    const now = performance.now();
    if (now - this.lastMouseMoveTime < this.mouseMoveThrottle) {
      return;
    }
    
    this.lastMouseMoveTime = now;
    // ... push event
  };
}
```

### Batching State Updates

```elixir
# Server broadcasts state at fixed 30fps interval
def handle_info(:tick, socket) do
  new_state = Game.update(socket.assigns.game_state, 33)
  
  socket = 
    socket
    |> assign(:game_state, new_state)
    |> push_event("game_state", serialize_state(new_state))
  
  Process.send_after(self(), :tick, 33)
  {:noreply, socket}
end
```

---

## Summary

- **6つのClient→Serverイベント**: mouse操作、ゲーム制御、スコア読み込み
- **2つのServer→Clientイベント**: ゲーム状態配信、スコア保存指示
- **Validation**: クライアントとサーバーの両側でバリデーション
- **Performance**: throttling + batching for 60fps client / 30fps server
