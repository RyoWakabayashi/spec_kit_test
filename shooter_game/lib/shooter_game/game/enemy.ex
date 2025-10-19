defmodule ShooterGame.Game.Enemy do
  @moduledoc """
  Enemy entity representing an enemy ship.
  """

  @enforce_keys [:id, :x, :y]
  defstruct [
    # string (UUID)
    :id,
    # float
    :x,
    # float
    :y,
    # integer
    width: 40,
    # integer
    height: 40,
    # float (pixels per tick)
    velocity_x: 0,
    # float (pixels per tick)
    velocity_y: 2,
    # integer
    health: 1,
    # integer
    max_health: 1,
    # integer (points awarded when destroyed)
    score_value: 10,
    # monotonic time
    last_fire_time: 0,
    # integer
    fire_interval_ms: 2000,
    # map (movement pattern configuration)
    movement_pattern: %{pattern_type: :linear, params: %{}, spawn_time: 0}
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
          max_health: pos_integer(),
          score_value: pos_integer(),
          last_fire_time: integer(),
          fire_interval_ms: pos_integer(),
          movement_pattern: map()
        }

  @doc """
  Creates a new enemy at the given position.
  """
  def new(x, y) do
    %__MODULE__{
      id: generate_id(),
      x: x,
      y: y
    }
  end

  @doc """
  Moves the enemy based on its velocity.
  """
  def move(%__MODULE__{} = enemy) do
    %{enemy | x: enemy.x + enemy.velocity_x, y: enemy.y + enemy.velocity_y}
  end

  @doc """
  Checks if the enemy can fire based on fire interval.
  """
  def can_fire?(%__MODULE__{} = enemy) do
    # Allow first shot (when last_fire_time is 0)
    if enemy.last_fire_time == 0 do
      true
    else
      current_time = System.monotonic_time(:millisecond)
      current_time - enemy.last_fire_time >= enemy.fire_interval_ms
    end
  end

  @doc """
  Creates a bullet from the enemy's position.
  """
  def fire_bullet(%__MODULE__{} = enemy) do
    if can_fire?(enemy) do
      bullet =
        ShooterGame.Game.Bullet.new(
          enemy.x + enemy.width / 2 - 4,
          enemy.y + enemy.height,
          6,
          :enemy
        )

      updated_enemy = %{enemy | last_fire_time: System.monotonic_time(:millisecond)}
      {:ok, bullet, updated_enemy}
    else
      {:error, :cooldown}
    end
  end

  @doc """
  Reduces enemy health by the specified damage amount.
  """
  def take_damage(%__MODULE__{} = enemy, damage) do
    %{enemy | health: max(0, enemy.health - damage)}
  end

  @doc """
  Checks if the enemy is dead (health <= 0).
  """
  def dead?(%__MODULE__{health: health}), do: health <= 0

  @doc """
  Creates a new enemy with difficulty level considerations.

  Applies difficulty-based health multiplier and movement pattern.
  """
  def new_with_difficulty(x, y, difficulty_level, pattern_type) do
    alias ShooterGame.Game.DifficultyLevel

    base_health = DifficultyLevel.calculate_base_health(difficulty_level.level)
    pattern = select_pattern(pattern_type, x)

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

  @doc """
  Updates enemy movement based on its movement pattern.
  """
  def update_movement(enemy, current_time_ms, game_width, game_height) do
    ShooterGame.Game.MovementPattern.apply_pattern(
      enemy,
      current_time_ms,
      game_width,
      game_height
    )
  end

  @doc """
  Calculates health based on difficulty level.
  """
  def calculate_health(difficulty_level) do
    ShooterGame.Game.DifficultyLevel.calculate_base_health(difficulty_level.level)
  end

  @doc """
  Selects and configures a movement pattern.
  """
  def select_pattern(pattern_type, base_x) do
    spawn_time = System.monotonic_time(:millisecond)
    params = ShooterGame.Game.MovementPattern.default_params_for(pattern_type, base_x)

    %{
      pattern_type: pattern_type,
      params: params,
      spawn_time: spawn_time
    }
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end
end
