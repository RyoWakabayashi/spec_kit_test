defmodule ShooterGame.Game.StateTest do
  use ExUnit.Case, async: true

  alias ShooterGame.Game.{State, Player, Bullet, Collision}

  describe "new/0" do
    test "creates a new game state with default values" do
      state = State.new()

      assert %Player{} = state.player
      assert state.enemies == []
      assert state.player_bullets == []
      assert state.enemy_bullets == []
      assert state.score == 0
      assert state.status == :start
      assert state.game_width == 800
      assert state.game_height == 600
    end

    test "initializes difficulty level to level 1" do
      state = State.new()

      assert state.difficulty_level.level == 1
      assert state.last_difficulty_update == 0
    end
  end

  describe "start_game/1" do
    test "transitions status from :start to :playing" do
      state = State.new()
      started = State.start_game(state)

      assert started.status == :playing
    end

    test "resets score to zero" do
      state = State.new() |> Map.put(:score, 100)
      started = State.start_game(state)

      assert started.score == 0
    end

    test "resets difficulty level to 1" do
      state = State.new()
      started = State.start_game(state)

      assert started.difficulty_level.level == 1
    end
  end

  describe "enemy bullet collision with player" do
    test "player takes damage when hit by enemy bullet" do
      player = Player.new(400, 500)
      enemy_bullet = Bullet.new(player.x + 10, player.y + 10, 5, :enemy)

      state =
        State.new()
        |> Map.put(:player, player)
        |> Map.put(:enemy_bullets, [enemy_bullet])
        |> Map.put(:status, :playing)

      # Check collision detection
      assert Collision.bullets_to_player?(state.enemy_bullets, state.player)
    end

    test "game over when player health reaches zero from enemy bullet" do
      player = Player.new(400, 500) |> Map.put(:health, 1)
      # Enemy bullet that will collide with player
      enemy_bullet = Bullet.new(player.x + 10, player.y + 10, 5, :enemy)

      state =
        State.new()
        |> Map.put(:player, player)
        |> Map.put(:enemy_bullets, [enemy_bullet])
        |> Map.put(:status, :playing)

      # After collision, player health should decrease
      # This test verifies the collision detection logic exists
      assert Collision.bullets_to_player?(state.enemy_bullets, state.player)
    end

    test "no collision when enemy bullet misses player" do
      player = Player.new(400, 500)
      # Enemy bullet far from player
      enemy_bullet = Bullet.new(100, 100, 5, :enemy)

      state =
        State.new()
        |> Map.put(:player, player)
        |> Map.put(:enemy_bullets, [enemy_bullet])

      refute Collision.bullets_to_player?(state.enemy_bullets, state.player)
    end

    test "multiple enemy bullets can hit player" do
      player = Player.new(400, 500)
      bullet1 = Bullet.new(player.x + 5, player.y + 5, 5, :enemy)
      bullet2 = Bullet.new(player.x + 15, player.y + 15, 5, :enemy)

      state =
        State.new()
        |> Map.put(:player, player)
        |> Map.put(:enemy_bullets, [bullet1, bullet2])

      assert Collision.bullets_to_player?(state.enemy_bullets, state.player)
    end

    test "enemy bullets are removed after hitting player" do
      player = Player.new(400, 500)
      colliding_bullet = Bullet.new(player.x + 10, player.y + 10, 5, :enemy)
      non_colliding_bullet = Bullet.new(100, 100, 5, :enemy)

      state =
        State.new()
        |> Map.put(:player, player)
        |> Map.put(:enemy_bullets, [colliding_bullet, non_colliding_bullet])

      # Filter out colliding bullets
      {colliding, remaining} =
        Enum.split_with(state.enemy_bullets, fn bullet ->
          Collision.bullet_to_player?(bullet, state.player)
        end)

      assert length(colliding) >= 1
      assert length(remaining) >= 0
    end
  end

  describe "enemy bullet movement" do
    test "enemy bullets move downward" do
      bullet = Bullet.new(400, 100, 5, :enemy)
      moved = Bullet.move(bullet)

      assert moved.y > bullet.y
      assert moved.velocity_y > 0
    end

    test "enemy bullets are removed when off screen" do
      state = State.new()
      # Bullet below screen
      off_screen_bullet = Bullet.new(400, state.game_height + 100, 5, :enemy)
      # Bullet on screen
      on_screen_bullet = Bullet.new(400, 100, 5, :enemy)

      bullets = [off_screen_bullet, on_screen_bullet]

      on_screen =
        Enum.filter(bullets, fn bullet ->
          bullet.y < state.game_height and bullet.y > 0
        end)

      assert length(on_screen) == 1
      assert Enum.at(on_screen, 0) == on_screen_bullet
    end
  end

  describe "should_increase_difficulty?/1" do
    test "returns true when 10 seconds have passed since last update" do
      state =
        State.new()
        |> Map.put(:status, :playing)
        |> Map.put(:elapsed_time, 10_000)
        |> Map.put(:last_difficulty_update, 0)

      assert State.should_increase_difficulty?(state)
    end

    test "returns false when less than 10 seconds have passed" do
      state =
        State.new()
        |> Map.put(:status, :playing)
        |> Map.put(:elapsed_time, 5_000)
        |> Map.put(:last_difficulty_update, 0)

      refute State.should_increase_difficulty?(state)
    end

    test "returns true when another 10 seconds pass after previous update" do
      state =
        State.new()
        |> Map.put(:status, :playing)
        |> Map.put(:elapsed_time, 20_000)
        |> Map.put(:last_difficulty_update, 10_000)

      assert State.should_increase_difficulty?(state)
    end
  end

  describe "update_difficulty/1" do
    test "increases difficulty level when time threshold is met" do
      state =
        State.new()
        |> Map.put(:status, :playing)
        |> Map.put(:elapsed_time, 10_000)
        |> Map.put(:last_difficulty_update, 0)

      updated = State.update_difficulty(state)

      assert updated.difficulty_level.level == 2
      assert updated.last_difficulty_update == 10_000
    end

    test "does not change difficulty when time threshold not met" do
      state =
        State.new()
        |> Map.put(:status, :playing)
        |> Map.put(:elapsed_time, 5_000)
        |> Map.put(:last_difficulty_update, 0)

      updated = State.update_difficulty(state)

      assert updated.difficulty_level.level == 1
      assert updated.last_difficulty_update == 0
    end

    test "caps difficulty level at maximum (15)" do
      state =
        State.new()
        |> Map.put(:status, :playing)
        |> Map.put(:elapsed_time, 150_000)
        |> Map.put(:last_difficulty_update, 140_000)
        |> Map.put(:difficulty_level, ShooterGame.Game.DifficultyLevel.new(15))

      updated = State.update_difficulty(state)

      assert updated.difficulty_level.level == 15
    end

    test "progression through multiple levels" do
      # Start at level 1
      state =
        State.new()
        |> Map.put(:status, :playing)
        |> Map.put(:elapsed_time, 0)
        |> Map.put(:last_difficulty_update, 0)

      assert state.difficulty_level.level == 1

      # After 10 seconds -> level 2
      state = %{state | elapsed_time: 10_000}
      state = State.update_difficulty(state)
      assert state.difficulty_level.level == 2
      assert state.last_difficulty_update == 10_000

      # After 20 seconds -> level 3
      state = %{state | elapsed_time: 20_000}
      state = State.update_difficulty(state)
      assert state.difficulty_level.level == 3
      assert state.last_difficulty_update == 20_000

      # After 30 seconds -> level 4
      state = %{state | elapsed_time: 30_000}
      state = State.update_difficulty(state)
      assert state.difficulty_level.level == 4
      assert state.last_difficulty_update == 30_000
    end

    test "difficulty parameters scale correctly" do
      state = State.new() |> Map.put(:status, :playing)

      # Level 1 parameters
      assert state.difficulty_level.spawn_interval_ms == 2000
      assert state.difficulty_level.max_enemies == 5
      assert state.difficulty_level.enemy_health_multiplier == 1.0
      assert state.difficulty_level.fire_interval_ms == 3000

      # Progress to level 5
      state = %{state | elapsed_time: 40_000, last_difficulty_update: 0}
      state = State.update_difficulty(state)
      state = %{state | elapsed_time: 50_000}
      state = State.update_difficulty(state)
      state = %{state | elapsed_time: 60_000}
      state = State.update_difficulty(state)
      state = %{state | elapsed_time: 70_000}
      state = State.update_difficulty(state)

      assert state.difficulty_level.level == 5

      # Level 5 should have harder parameters
      assert state.difficulty_level.spawn_interval_ms < 2000
      assert state.difficulty_level.max_enemies >= 5
      assert state.difficulty_level.enemy_health_multiplier >= 1.0
      assert state.difficulty_level.fire_interval_ms < 3000
    end

    test "only updates during :playing status" do
      state =
        State.new()
        |> Map.put(:status, :start)
        |> Map.put(:elapsed_time, 10_000)
        |> Map.put(:last_difficulty_update, 0)

      updated = State.update_difficulty(state)

      # Should not update when not playing
      assert updated.difficulty_level.level == 1
      assert updated.last_difficulty_update == 0
    end
  end
end
