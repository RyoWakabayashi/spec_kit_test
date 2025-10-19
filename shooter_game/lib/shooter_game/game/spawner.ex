defmodule ShooterGame.Game.Spawner do
  @moduledoc """
  Handles enemy spawning logic with difficulty scaling.
  """

  alias ShooterGame.Game.{State, Enemy}

  @doc """
  Checks if it's time to spawn a new enemy based on difficulty settings.
  """
  def should_spawn?(%State{} = state) do
    current_time = System.monotonic_time(:millisecond)
    time_elapsed = current_time - state.last_spawn_time
    spawn_interval = state.difficulty_level.spawn_interval_ms
    max_enemies = state.difficulty_level.max_enemies

    # Spawn if interval passed and under max enemy count
    time_elapsed >= spawn_interval and length(state.enemies) < max_enemies
  end

  @doc """
  Spawns a new enemy at a random position at the top of the screen.
  Enemy is created with difficulty-appropriate health and fire interval.
  """
  def spawn_enemy(%State{} = state) do
    x = :rand.uniform(state.game_width - 50)

    # Select a random pattern from difficulty level's available patterns
    patterns = state.difficulty_level.movement_patterns
    pattern_type = Enum.random(patterns)

    # Create enemy with difficulty scaling
    enemy = Enemy.new_with_difficulty(x, 0, state.difficulty_level, pattern_type)

    # Override fire interval from difficulty settings
    enemy = %{enemy | fire_interval_ms: state.difficulty_level.fire_interval_ms}

    %{
      state
      | enemies: [enemy | state.enemies],
        last_spawn_time: System.monotonic_time(:millisecond)
    }
  end
end
