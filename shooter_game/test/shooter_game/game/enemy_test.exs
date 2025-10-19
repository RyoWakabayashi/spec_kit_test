defmodule ShooterGame.Game.EnemyTest do
  use ExUnit.Case, async: true

  alias ShooterGame.Game.Enemy
  alias ShooterGame.Game.Bullet

  describe "new/2" do
    test "creates a new enemy with default values" do
      enemy = Enemy.new(100.0, 50.0)

      assert enemy.x == 100.0
      assert enemy.y == 50.0
      assert enemy.health == 1
      assert enemy.max_health == 1
      assert enemy.width == 40
      assert enemy.height == 40
      assert enemy.velocity_y == 2
      assert enemy.fire_interval_ms == 2000
      assert is_binary(enemy.id)
    end
  end

  describe "move/1" do
    test "moves enemy based on velocity" do
      enemy = Enemy.new(100.0, 50.0)
      moved = Enemy.move(enemy)

      assert moved.x == enemy.x + enemy.velocity_x
      assert moved.y == enemy.y + enemy.velocity_y
    end
  end

  describe "can_fire?/1" do
    test "returns true when fire interval has passed" do
      enemy = Enemy.new(100.0, 50.0)
      # Default last_fire_time is 0, so it should be able to fire immediately
      assert Enemy.can_fire?(enemy)
    end

    test "returns false when fire interval has not passed" do
      enemy =
        Enemy.new(100.0, 50.0)
        |> Map.put(:last_fire_time, System.monotonic_time(:millisecond))

      refute Enemy.can_fire?(enemy)
    end

    test "returns true after fire interval has elapsed" do
      past_time = System.monotonic_time(:millisecond) - 2500
      enemy = Enemy.new(100.0, 50.0) |> Map.put(:last_fire_time, past_time)

      assert Enemy.can_fire?(enemy)
    end
  end

  describe "fire_bullet/1" do
    test "creates a bullet when fire interval allows" do
      enemy = Enemy.new(100.0, 50.0)
      {:ok, bullet, updated_enemy} = Enemy.fire_bullet(enemy)

      assert %Bullet{} = bullet
      assert bullet.owner_type == :enemy
      # Bullet should be centered horizontally on enemy
      expected_x = enemy.x + enemy.width / 2 - 4
      assert_in_delta bullet.x, expected_x, 0.1
      # Bullet should be at bottom of enemy
      assert bullet.y == enemy.y + enemy.height
      assert bullet.velocity_y == 6
      # Enemy's last_fire_time should be updated to current time
      assert updated_enemy.last_fire_time != 0
    end

    test "returns error when fire interval has not passed" do
      enemy =
        Enemy.new(100.0, 50.0)
        |> Map.put(:last_fire_time, System.monotonic_time(:millisecond))

      assert {:error, :cooldown} = Enemy.fire_bullet(enemy)
    end

    test "creates bullet moving downward (positive velocity)" do
      enemy = Enemy.new(100.0, 50.0)
      {:ok, bullet, _updated_enemy} = Enemy.fire_bullet(enemy)

      assert bullet.velocity_y > 0
    end

    test "bullet originates from center of enemy" do
      enemy = Enemy.new(150.0, 100.0)
      {:ok, bullet, _updated_enemy} = Enemy.fire_bullet(enemy)

      expected_x = 150.0 + 40 / 2 - 4
      assert_in_delta bullet.x, expected_x, 0.1
      assert bullet.y == 100.0 + 40
    end
  end

  describe "take_damage/2" do
    test "reduces health by damage amount" do
      enemy = Enemy.new(100.0, 50.0) |> Map.put(:health, 3)
      damaged = Enemy.take_damage(enemy, 1)

      assert damaged.health == 2
    end

    test "health does not go below zero" do
      enemy = Enemy.new(100.0, 50.0) |> Map.put(:health, 1)
      damaged = Enemy.take_damage(enemy, 5)

      assert damaged.health == 0
    end
  end

  describe "dead?/1" do
    test "returns true when health is zero" do
      enemy = Enemy.new(100.0, 50.0) |> Map.put(:health, 0)
      assert Enemy.dead?(enemy)
    end

    test "returns false when health is positive" do
      enemy = Enemy.new(100.0, 50.0) |> Map.put(:health, 1)
      refute Enemy.dead?(enemy)
    end
  end

  describe "new_with_difficulty/4" do
    test "creates enemy with difficulty-scaled health" do
      difficulty = ShooterGame.Game.DifficultyLevel.new(5)
      enemy = Enemy.new_with_difficulty(100.0, 50.0, difficulty, :linear)

      # Level 5 should have higher health than level 1
      assert enemy.health > 1
      assert enemy.max_health == enemy.health
    end

    test "creates enemy with specified movement pattern" do
      difficulty = ShooterGame.Game.DifficultyLevel.new(1)
      enemy = Enemy.new_with_difficulty(100.0, 50.0, difficulty, :zigzag)

      assert enemy.movement_pattern.pattern_type == :zigzag
    end

    test "initializes movement pattern with spawn_time" do
      difficulty = ShooterGame.Game.DifficultyLevel.new(1)
      enemy = Enemy.new_with_difficulty(100.0, 50.0, difficulty, :sine_wave)

      assert enemy.movement_pattern.spawn_time != 0
      assert is_integer(enemy.movement_pattern.spawn_time)
    end
  end

  describe "update_movement/4" do
    test "applies linear movement pattern" do
      difficulty = ShooterGame.Game.DifficultyLevel.new(1)
      enemy = Enemy.new_with_difficulty(100.0, 50.0, difficulty, :linear)

      # Linear movement should only move vertically
      updated = Enemy.update_movement(enemy, 1000, 800, 600)

      assert updated.y > enemy.y
      # X should remain relatively stable for linear
      assert_in_delta updated.x, enemy.x, 1.0
    end

    test "applies zigzag movement pattern" do
      difficulty = ShooterGame.Game.DifficultyLevel.new(2)
      enemy = Enemy.new_with_difficulty(100.0, 50.0, difficulty, :zigzag)

      # Zigzag should have horizontal movement
      updated = Enemy.update_movement(enemy, 1000, 800, 600)

      assert updated.y > enemy.y
      # X may change with zigzag pattern
    end

    test "applies sine wave movement pattern" do
      difficulty = ShooterGame.Game.DifficultyLevel.new(3)
      enemy = Enemy.new_with_difficulty(200.0, 50.0, difficulty, :sine_wave)

      # Apply movement multiple times to see pattern
      updated1 = Enemy.update_movement(enemy, 100, 800, 600)
      updated2 = Enemy.update_movement(updated1, 200, 800, 600)
      updated3 = Enemy.update_movement(updated2, 300, 800, 600)

      # Sine wave should create horizontal oscillation
      assert updated3.y > enemy.y
    end

    test "clamps enemy position within bounds" do
      difficulty = ShooterGame.Game.DifficultyLevel.new(1)
      # Enemy at edge of screen
      enemy = Enemy.new_with_difficulty(750.0, 50.0, difficulty, :zigzag)

      # Movement should keep enemy within bounds
      updated = Enemy.update_movement(enemy, 1000, 800, 600)

      assert updated.x >= 0
      assert updated.x <= 800 - enemy.width
    end
  end

  describe "select_pattern/2" do
    test "returns valid movement pattern configuration" do
      pattern = Enemy.select_pattern(:linear, 100.0)

      assert pattern.pattern_type == :linear
      assert is_map(pattern.params)
      assert is_integer(pattern.spawn_time)
    end

    test "configures sine wave with base_x" do
      pattern = Enemy.select_pattern(:sine_wave, 200.0)

      assert pattern.pattern_type == :sine_wave
      assert pattern.params.base_x == 200.0
    end

    test "configures circular with center position" do
      pattern = Enemy.select_pattern(:circular, 300.0)

      assert pattern.pattern_type == :circular
      assert pattern.params.center_x == 300.0
    end
  end

  describe "calculate_health/1" do
    test "scales health with difficulty level" do
      difficulty_1 = ShooterGame.Game.DifficultyLevel.new(1)
      difficulty_5 = ShooterGame.Game.DifficultyLevel.new(5)
      difficulty_10 = ShooterGame.Game.DifficultyLevel.new(10)

      health_level_1 = Enemy.calculate_health(difficulty_1)
      health_level_5 = Enemy.calculate_health(difficulty_5)
      health_level_10 = Enemy.calculate_health(difficulty_10)

      assert health_level_1 == 1
      assert health_level_5 > health_level_1
      assert health_level_10 > health_level_5
    end

    test "caps health at reasonable maximum" do
      difficulty_15 = ShooterGame.Game.DifficultyLevel.new(15)
      health_level_15 = Enemy.calculate_health(difficulty_15)

      # Should not exceed 10 HP (as per DifficultyLevel)
      assert health_level_15 <= 10
    end
  end
end
