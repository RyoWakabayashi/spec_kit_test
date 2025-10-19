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
    # integer (points awarded when destroyed)
    score_value: 10,
    # monotonic time
    last_fire_time: 0,
    # integer
    fire_interval_ms: 2000
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
    current_time = System.monotonic_time(:millisecond)
    current_time - enemy.last_fire_time >= enemy.fire_interval_ms
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

  defp generate_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end
end
