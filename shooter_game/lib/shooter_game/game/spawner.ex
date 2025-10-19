defmodule ShooterGame.Game.Spawner do
  @moduledoc """
  Handles enemy spawning logic.
  """

  alias ShooterGame.Game.{State, Enemy}

  @spawn_interval_ms 2000

  @doc """
  Checks if it's time to spawn a new enemy.
  """
  def should_spawn?(%State{} = state) do
    current_time = System.monotonic_time(:millisecond)
    current_time - state.last_spawn_time >= @spawn_interval_ms
  end

  @doc """
  Spawns a new enemy at a random position at the top of the screen.
  """
  def spawn_enemy(%State{} = state) do
    x = :rand.uniform(state.game_width - 50)
    enemy = Enemy.new(x, 0)

    %{
      state
      | enemies: [enemy | state.enemies],
        last_spawn_time: System.monotonic_time(:millisecond)
    }
  end
end
