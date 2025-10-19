defmodule ShooterGame.Game.State do
  @moduledoc """
  Game state entity representing the entire game state.
  """

  alias ShooterGame.Game.{Player, Enemy, Bullet, DifficultyLevel}

  @enforce_keys [:player, :status]
  defstruct [
    # %Player{}
    :player,
    # [%Enemy{}]
    enemies: [],
    # [%Bullet{}]
    player_bullets: [],
    # [%Bullet{}]
    enemy_bullets: [],
    # integer
    score: 0,
    # integer
    high_score: 0,
    # :start | :playing | :game_over
    status: :start,
    # integer (pixels)
    game_width: 800,
    # integer (pixels)
    game_height: 600,
    # monotonic time
    last_spawn_time: 0,
    # milliseconds since game start
    elapsed_time: 0,
    # 3 minutes in milliseconds
    time_limit: 180_000,
    # %DifficultyLevel{}
    difficulty_level: nil,
    # integer (milliseconds)
    last_difficulty_update: 0
  ]

  @type status :: :start | :playing | :game_over

  @type t :: %__MODULE__{
          player: Player.t(),
          enemies: [Enemy.t()],
          player_bullets: [Bullet.t()],
          enemy_bullets: [Bullet.t()],
          score: non_neg_integer(),
          high_score: non_neg_integer(),
          status: status(),
          game_width: pos_integer(),
          game_height: pos_integer(),
          last_spawn_time: integer(),
          elapsed_time: non_neg_integer(),
          time_limit: pos_integer(),
          difficulty_level: DifficultyLevel.t() | nil,
          last_difficulty_update: non_neg_integer()
        }

  @doc """
  Creates a new game state with default values.
  """
  def new(high_score \\ 0) do
    %__MODULE__{
      player: Player.new(400, 500),
      high_score: high_score,
      status: :start,
      difficulty_level: DifficultyLevel.new(1),
      last_difficulty_update: 0
    }
  end

  @doc """
  Starts the game by setting status to :playing.
  """
  def start_game(%__MODULE__{} = state) do
    %{
      state
      | status: :playing,
        score: 0,
        elapsed_time: 0,
        difficulty_level: DifficultyLevel.new(1),
        last_difficulty_update: 0,
        last_spawn_time: System.monotonic_time(:millisecond)
    }
  end

  @doc """
  Ends the game by setting status to :game_over.
  """
  def game_over(%__MODULE__{} = state) do
    new_high_score = max(state.score, state.high_score)
    %{state | status: :game_over, high_score: new_high_score}
  end

  @doc """
  Updates the elapsed time.
  """
  def update_elapsed_time(%__MODULE__{} = state, delta_ms) do
    %{state | elapsed_time: state.elapsed_time + delta_ms}
  end

  @doc """
  Adds score to the current score.
  """
  def add_score(%__MODULE__{} = state, points) when points > 0 do
    %{state | score: state.score + points}
  end

  @doc """
  Updates difficulty level based on elapsed time.

  Difficulty increases every 10 seconds (10,000 milliseconds).
  """
  def update_difficulty(%__MODULE__{status: :playing} = state) do
    current_level_duration = state.elapsed_time - state.last_difficulty_update

    if current_level_duration >= 10_000 do
      new_difficulty = DifficultyLevel.next_level(state.difficulty_level)

      %{
        state
        | difficulty_level: new_difficulty,
          last_difficulty_update: state.elapsed_time
      }
    else
      state
    end
  end

  def update_difficulty(state), do: state

  @doc """
  Checks if difficulty should increase.
  """
  def should_increase_difficulty?(%__MODULE__{status: :playing} = state) do
    state.elapsed_time - state.last_difficulty_update >= 10_000
  end

  def should_increase_difficulty?(_state), do: false
end
