defmodule ShooterGame.Game.Player do
  @moduledoc """
  Player entity representing the player's ship.
  """

  @enforce_keys [:id, :x, :y]
  defstruct [
    # string (UUID)
    :id,
    # float (pixels)
    :x,
    # float (pixels)
    :y,
    # integer (pixels)
    width: 40,
    # integer (pixels)
    height: 40,
    # boolean
    is_firing: false,
    # monotonic time
    last_fire_time: 0,
    # integer
    fire_cooldown_ms: 150
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          x: float(),
          y: float(),
          width: pos_integer(),
          height: pos_integer(),
          is_firing: boolean(),
          last_fire_time: integer(),
          fire_cooldown_ms: pos_integer()
        }

  @doc """
  Creates a new player at the given position.
  """
  def new(x, y) do
    %__MODULE__{
      id: generate_id(),
      x: x,
      y: y
    }
  end

  @doc """
  Moves the player to the specified position.
  Ensures the player stays within bounds.
  """
  def move_to(%__MODULE__{} = player, x, y, game_width, game_height) do
    new_x = max(0, min(x, game_width - player.width))
    new_y = max(0, min(y, game_height - player.height))

    %{player | x: new_x, y: new_y}
  end

  @doc """
  Starts firing bullets.
  """
  def start_firing(%__MODULE__{} = player) do
    %{player | is_firing: true}
  end

  @doc """
  Stops firing bullets.
  """
  def stop_firing(%__MODULE__{} = player) do
    %{player | is_firing: false}
  end

  @doc """
  Checks if the player can fire a bullet based on cooldown.
  """
  def can_fire?(%__MODULE__{last_fire_time: 0} = _player), do: true

  def can_fire?(%__MODULE__{} = player) do
    current_time = System.monotonic_time(:millisecond)
    current_time - player.last_fire_time >= player.fire_cooldown_ms
  end

  @doc """
  Creates a bullet from the player's position and updates last fire time.
  """
  def fire_bullet(%__MODULE__{} = player) do
    if can_fire?(player) do
      bullet =
        ShooterGame.Game.Bullet.new(
          player.x + player.width / 2 - 4,
          player.y,
          -8,
          :player
        )

      updated_player = %{player | last_fire_time: System.monotonic_time(:millisecond)}
      {:ok, bullet, updated_player}
    else
      {:error, :cooldown}
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end
end
