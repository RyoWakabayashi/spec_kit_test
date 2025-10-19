defmodule ShooterGame.Game.Bullet do
  @moduledoc """
  Bullet entity representing a projectile.
  """

  @enforce_keys [:id, :x, :y, :velocity_y, :owner_type]
  defstruct [
    # string (UUID)
    :id,
    # float
    :x,
    # float
    :y,
    # float (negative = upward, positive = downward)
    :velocity_y,
    # :player | :enemy
    :owner_type,
    # integer
    width: 8,
    # integer
    height: 16,
    # integer
    damage: 1
  ]

  @type owner_type :: :player | :enemy

  @type t :: %__MODULE__{
          id: String.t(),
          x: float(),
          y: float(),
          velocity_y: float(),
          owner_type: owner_type(),
          width: pos_integer(),
          height: pos_integer(),
          damage: pos_integer()
        }

  @doc """
  Creates a new bullet.
  """
  def new(x, y, velocity_y, owner_type) do
    %__MODULE__{
      id: generate_id(),
      x: x,
      y: y,
      velocity_y: velocity_y,
      owner_type: owner_type
    }
  end

  @doc """
  Moves the bullet based on its velocity.
  """
  def move(%__MODULE__{} = bullet) do
    %{bullet | y: bullet.y + bullet.velocity_y}
  end

  @doc """
  Checks if the bullet is off-screen.
  """
  def off_screen?(%__MODULE__{} = bullet, game_height) do
    bullet.y < -bullet.height or bullet.y > game_height
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end
end
