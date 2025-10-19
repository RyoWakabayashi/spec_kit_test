defmodule ShooterGameWeb.GameLive do
  use ShooterGameWeb, :live_view

  alias ShooterGame.Game.State

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:game_state, State.new())
      |> assign(:timer_ref, nil)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="game-container" phx-hook="StorageHook" id="storage-hook">
      <div class="game-ui">
        <div class="score">Score: {@game_state.score}</div>
        <div class="high-score">High Score: {@game_state.high_score}</div>
        <div class="time">
          Time: {div(@game_state.elapsed_time, 1000)}s / {div(
            @game_state.time_limit,
            1000
          )}s
        </div>
        <div class="difficulty-level">
          Level: {@game_state.difficulty_level.level}
        </div>
      </div>

      <canvas
        id="game-canvas"
        phx-hook="GameCanvas"
        width="800"
        height="600"
        phx-update="ignore"
      >
      </canvas>

      <%= if @game_state.status == :start do %>
        <div class="start-screen">
          <h1>Shooter Game</h1>
          <p>High Score: {@game_state.high_score}</p>
          <button class="game-button" phx-click="start_game">START</button>
        </div>
      <% end %>

      <%= if @game_state.status == :game_over do %>
        <div class="game-over-screen">
          <h1>GAME OVER</h1>
          <p>Score: {@game_state.score}</p>
          <p>High Score: {@game_state.high_score}</p>
          <button class="game-button" phx-click="restart_game">RETRY</button>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("start_game", _params, socket) do
    state = State.start_game(socket.assigns.game_state)

    socket =
      socket
      |> assign(:game_state, state)
      |> start_game_loop()

    {:noreply, socket}
  end

  @impl true
  def handle_event("restart_game", _params, socket) do
    state = State.new(socket.assigns.game_state.high_score)

    socket =
      socket
      |> assign(:game_state, state)
      |> cancel_game_loop()

    {:noreply, socket}
  end

  @impl true
  def handle_event("mouse_move", %{"x" => x, "y" => y}, socket) do
    state = socket.assigns.game_state

    if state.status == :playing do
      player =
        ShooterGame.Game.Player.move_to(
          state.player,
          x,
          y,
          state.game_width,
          state.game_height
        )

      state = %{state | player: player}
      {:noreply, assign(socket, :game_state, state)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("mouse_down", _params, socket) do
    state = socket.assigns.game_state

    if state.status == :playing do
      player = ShooterGame.Game.Player.start_firing(state.player)
      state = %{state | player: player}
      {:noreply, assign(socket, :game_state, state)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("mouse_up", _params, socket) do
    state = socket.assigns.game_state

    if state.status == :playing do
      player = ShooterGame.Game.Player.stop_firing(state.player)
      state = %{state | player: player}
      {:noreply, assign(socket, :game_state, state)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("high_score_loaded", %{"highScore" => high_score}, socket) do
    state = %{socket.assigns.game_state | high_score: high_score}
    {:noreply, assign(socket, :game_state, state)}
  end

  @impl true
  def handle_info(:tick, socket) do
    state = socket.assigns.game_state

    if state.status == :playing do
      state = update_game_state(state)

      socket = assign(socket, :game_state, state)

      # Push game state to client
      socket = push_event(socket, "game_state", serialize_game_state(state))

      # Check game over conditions
      socket =
        if state.elapsed_time >= state.time_limit or state.status == :game_over do
          state = State.game_over(state)

          socket
          |> assign(:game_state, state)
          |> push_event("save_score", %{score: state.score})
          |> cancel_game_loop()
        else
          # Schedule next tick
          Process.send_after(self(), :tick, 33)
          socket
        end

      {:noreply, socket}
    else
      {:noreply, cancel_game_loop(socket)}
    end
  end

  defp start_game_loop(socket) do
    # Cancel existing timer if any
    socket = cancel_game_loop(socket)

    # Start new timer
    Process.send_after(self(), :tick, 33)
    socket
  end

  defp cancel_game_loop(socket) do
    if socket.assigns.timer_ref do
      Process.cancel_timer(socket.assigns.timer_ref)
    end

    assign(socket, :timer_ref, nil)
  end

  defp update_game_state(state) do
    state
    |> State.update_elapsed_time(33)
    |> State.update_difficulty()
    |> update_bullets()
    |> spawn_enemies()
    |> update_enemies()
    |> handle_player_firing()
    |> handle_enemy_firing()
    |> detect_collisions()
    |> remove_off_screen_entities()
  end

  defp update_bullets(state) do
    player_bullets = Enum.map(state.player_bullets, &ShooterGame.Game.Bullet.move/1)
    enemy_bullets = Enum.map(state.enemy_bullets, &ShooterGame.Game.Bullet.move/1)

    %{state | player_bullets: player_bullets, enemy_bullets: enemy_bullets}
  end

  defp spawn_enemies(state) do
    if ShooterGame.Game.Spawner.should_spawn?(state) do
      ShooterGame.Game.Spawner.spawn_enemy(state)
    else
      state
    end
  end

  defp update_enemies(state) do
    current_time = System.monotonic_time(:millisecond)

    enemies =
      Enum.map(state.enemies, fn enemy ->
        # Apply movement pattern if enemy has one
        if enemy.movement_pattern && enemy.movement_pattern.pattern_type do
          ShooterGame.Game.Enemy.update_movement(
            enemy,
            current_time,
            state.game_width,
            state.game_height
          )
        else
          # Fallback to simple linear movement
          ShooterGame.Game.Enemy.move(enemy)
        end
      end)

    %{state | enemies: enemies}
  end

  defp handle_player_firing(state) do
    if state.player.is_firing do
      case ShooterGame.Game.Player.fire_bullet(state.player) do
        {:ok, bullet, player} ->
          %{state | player: player, player_bullets: [bullet | state.player_bullets]}

        {:error, :cooldown} ->
          state
      end
    else
      state
    end
  end

  defp handle_enemy_firing(state) do
    {new_bullets, updated_enemies} =
      Enum.reduce(state.enemies, {state.enemy_bullets, []}, fn enemy,
                                                               {bullets_acc, enemies_acc} ->
        case ShooterGame.Game.Enemy.fire_bullet(enemy) do
          {:ok, bullet, updated_enemy} ->
            {[bullet | bullets_acc], [updated_enemy | enemies_acc]}

          {:error, :cooldown} ->
            {bullets_acc, [enemy | enemies_acc]}
        end
      end)

    %{state | enemy_bullets: new_bullets, enemies: Enum.reverse(updated_enemies)}
  end

  defp detect_collisions(state) do
    alias ShooterGame.Game.Collision

    # Detect player bullets hitting enemies
    bullet_enemy_collisions =
      Collision.detect_player_bullet_enemy_collisions(state.player_bullets, state.enemies)

    # Remove hit bullets and enemies, add score
    {remaining_bullets, remaining_enemies, score_gained} =
      process_bullet_enemy_collisions(
        state.player_bullets,
        state.enemies,
        bullet_enemy_collisions
      )

    state = %{
      state
      | player_bullets: remaining_bullets,
        enemies: remaining_enemies,
        score: state.score + score_gained
    }

    # Detect enemy bullets hitting player
    hit_bullet_ids =
      Collision.detect_enemy_bullet_player_collisions(state.enemy_bullets, state.player)

    if length(hit_bullet_ids) > 0 do
      # Player was hit - game over
      State.game_over(state)
    else
      # Check if enemy collides with player
      if Collision.detect_enemy_player_collisions(state.enemies, state.player) do
        State.game_over(state)
      else
        # Remove bullets that hit player
        enemy_bullets =
          Enum.reject(state.enemy_bullets, fn bullet -> bullet.id in hit_bullet_ids end)

        %{state | enemy_bullets: enemy_bullets}
      end
    end
  end

  defp process_bullet_enemy_collisions(bullets, enemies, collisions) do
    hit_bullet_ids = Enum.map(collisions, fn {bullet_id, _} -> bullet_id end) |> MapSet.new()
    hit_enemy_ids = Enum.map(collisions, fn {_, enemy_id} -> enemy_id end) |> MapSet.new()

    remaining_bullets =
      Enum.reject(bullets, fn bullet -> MapSet.member?(hit_bullet_ids, bullet.id) end)

    # Process enemies: remove dead ones, calculate score
    {remaining_enemies, score} =
      Enum.reduce(enemies, {[], 0}, fn enemy, {acc_enemies, acc_score} ->
        if MapSet.member?(hit_enemy_ids, enemy.id) do
          # Enemy was hit - add score, don't keep enemy
          {acc_enemies, acc_score + enemy.score_value}
        else
          {[enemy | acc_enemies], acc_score}
        end
      end)

    {remaining_bullets, Enum.reverse(remaining_enemies), score}
  end

  defp remove_off_screen_entities(state) do
    player_bullets =
      Enum.reject(state.player_bullets, fn bullet ->
        ShooterGame.Game.Bullet.off_screen?(bullet, state.game_height)
      end)

    enemy_bullets =
      Enum.reject(state.enemy_bullets, fn bullet ->
        ShooterGame.Game.Bullet.off_screen?(bullet, state.game_height)
      end)

    enemies =
      Enum.reject(state.enemies, fn enemy ->
        enemy.y > state.game_height
      end)

    %{state | player_bullets: player_bullets, enemy_bullets: enemy_bullets, enemies: enemies}
  end

  defp serialize_game_state(state) do
    %{
      player: %{
        x: state.player.x,
        y: state.player.y,
        width: state.player.width,
        height: state.player.height
      },
      enemies:
        Enum.map(state.enemies, fn enemy ->
          %{x: enemy.x, y: enemy.y, width: enemy.width, height: enemy.height}
        end),
      player_bullets:
        Enum.map(state.player_bullets, fn bullet ->
          %{x: bullet.x, y: bullet.y, width: bullet.width, height: bullet.height}
        end),
      enemy_bullets:
        Enum.map(state.enemy_bullets, fn bullet ->
          %{x: bullet.x, y: bullet.y, width: bullet.width, height: bullet.height}
        end),
      score: state.score,
      elapsed_time: state.elapsed_time
    }
  end
end
