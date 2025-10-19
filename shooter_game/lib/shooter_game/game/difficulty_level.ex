defmodule ShooterGame.Game.DifficultyLevel do
  @moduledoc """
  難易度レベルの設定とレベル遷移ロジックを管理

  各レベルには以下のパラメータが含まれます:
  - spawn_interval_ms: 敵出現間隔（ミリ秒）
  - max_enemies: 画面上の最大敵数
  - enemy_health_multiplier: 敵耐久力の倍率
  - fire_interval_ms: 敵弾発射間隔（ミリ秒）
  - movement_patterns: 使用可能な移動パターンリスト
  """

  @enforce_keys [:level]
  defstruct [
    :level,
    spawn_interval_ms: 2000,
    max_enemies: 5,
    enemy_health_multiplier: 1.0,
    fire_interval_ms: 3000,
    movement_patterns: [:linear]
  ]

  @type t :: %__MODULE__{
          level: pos_integer(),
          spawn_interval_ms: pos_integer(),
          max_enemies: pos_integer(),
          enemy_health_multiplier: float(),
          fire_interval_ms: pos_integer(),
          movement_patterns: [atom()]
        }

  # レベル定義（研究成果に基づく）
  @level_configs %{
    1 => %{
      spawn_interval_ms: 2000,
      max_enemies: 5,
      health_multi: 1.0,
      fire_interval_ms: 3000,
      patterns: [:linear]
    },
    2 => %{
      spawn_interval_ms: 1800,
      max_enemies: 7,
      health_multi: 1.0,
      fire_interval_ms: 2800,
      patterns: [:linear, :zigzag]
    },
    3 => %{
      spawn_interval_ms: 1600,
      max_enemies: 9,
      health_multi: 1.5,
      fire_interval_ms: 2600,
      patterns: [:zigzag, :sine_wave]
    },
    4 => %{
      spawn_interval_ms: 1400,
      max_enemies: 11,
      health_multi: 2.0,
      fire_interval_ms: 2400,
      patterns: [:sine_wave, :circular]
    },
    5 => %{
      spawn_interval_ms: 1200,
      max_enemies: 13,
      health_multi: 2.5,
      fire_interval_ms: 2200,
      patterns: [:sine_wave, :circular, :spiral]
    },
    6 => %{
      spawn_interval_ms: 1100,
      max_enemies: 15,
      health_multi: 3.0,
      fire_interval_ms: 2000,
      patterns: [:circular, :spiral, :random_walk]
    },
    7 => %{
      spawn_interval_ms: 1000,
      max_enemies: 16,
      health_multi: 3.5,
      fire_interval_ms: 1900,
      patterns: [:spiral, :random_walk, :sine_wave]
    },
    8 => %{
      spawn_interval_ms: 900,
      max_enemies: 17,
      health_multi: 4.0,
      fire_interval_ms: 1800,
      patterns: [:random_walk, :circular, :zigzag]
    },
    9 => %{
      spawn_interval_ms: 800,
      max_enemies: 18,
      health_multi: 4.5,
      fire_interval_ms: 1700,
      patterns: [:circular, :spiral, :sine_wave, :random_walk]
    },
    10 => %{
      spawn_interval_ms: 700,
      max_enemies: 19,
      health_multi: 5.0,
      fire_interval_ms: 1600,
      patterns: [:sine_wave, :circular, :spiral, :random_walk]
    },
    11 => %{
      spawn_interval_ms: 650,
      max_enemies: 19,
      health_multi: 5.0,
      fire_interval_ms: 1500,
      patterns: [:sine_wave, :circular, :spiral, :random_walk]
    },
    12 => %{
      spawn_interval_ms: 600,
      max_enemies: 20,
      health_multi: 5.0,
      fire_interval_ms: 1400,
      patterns: [:sine_wave, :circular, :spiral, :random_walk]
    },
    13 => %{
      spawn_interval_ms: 550,
      max_enemies: 20,
      health_multi: 5.0,
      fire_interval_ms: 1300,
      patterns: [:sine_wave, :circular, :spiral, :random_walk]
    },
    14 => %{
      spawn_interval_ms: 500,
      max_enemies: 20,
      health_multi: 5.0,
      fire_interval_ms: 1200,
      patterns: [:sine_wave, :circular, :spiral, :random_walk]
    },
    15 => %{
      spawn_interval_ms: 500,
      max_enemies: 20,
      health_multi: 5.0,
      fire_interval_ms: 1000,
      patterns: [:sine_wave, :circular, :spiral, :random_walk]
    }
  }

  @doc """
  新しい難易度レベルを生成

  ## Examples

      iex> DifficultyLevel.new()
      %DifficultyLevel{level: 1, max_enemies: 5, ...}

      iex> DifficultyLevel.new(5)
      %DifficultyLevel{level: 5, max_enemies: 13, ...}
  """
  @spec new(pos_integer()) :: t()
  def new(level \\ 1), do: get_config(level)

  @doc """
  次のレベルに進める（最大レベル15）

  ## Examples

      iex> level = DifficultyLevel.new(1)
      iex> next = DifficultyLevel.next_level(level)
      iex> next.level
      2

      iex> level = DifficultyLevel.new(15)
      iex> next = DifficultyLevel.next_level(level)
      iex> next.level
      15
  """
  @spec next_level(t()) :: t()
  def next_level(%__MODULE__{level: level}) do
    new_level = min(level + 1, 15)
    get_config(new_level)
  end

  @doc """
  レベル番号から設定を取得

  レベルは1から15の範囲で有効です。
  範囲外の値が指定された場合、最も近い有効な値にクランプされます。

  ## Examples

      iex> DifficultyLevel.get_config(1)
      %DifficultyLevel{level: 1, max_enemies: 5, ...}

      iex> DifficultyLevel.get_config(20)
      %DifficultyLevel{level: 15, ...}
  """
  @spec get_config(integer()) :: t()
  def get_config(level) when is_integer(level) do
    # レベルを1-15の範囲にクランプ
    clamped_level = max(1, min(level, 15))
    config = Map.get(@level_configs, clamped_level, @level_configs[1])

    %__MODULE__{
      level: clamped_level,
      spawn_interval_ms: config.spawn_interval_ms,
      max_enemies: config.max_enemies,
      enemy_health_multiplier: config.health_multi,
      fire_interval_ms: config.fire_interval_ms,
      movement_patterns: config.patterns
    }
  end

  @doc """
  レベルに基づいて基礎耐久力を計算

  ## Examples

      iex> DifficultyLevel.calculate_base_health(1)
      1

      iex> DifficultyLevel.calculate_base_health(3)
      1
  """
  @spec calculate_base_health(pos_integer()) :: pos_integer()
  def calculate_base_health(level) when is_integer(level) and level >= 1 do
    config = get_config(level)
    max(1, floor(1 * config.enemy_health_multiplier))
  end
end
