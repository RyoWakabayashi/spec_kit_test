defmodule ShooterGame.Game.MovementPattern do
  @moduledoc """
  敵の移動パターンを計算する純粋関数群

  各パターンは時間ベースの計算を使用し、フレームレート非依存で動作します。
  すべての関数は純粋関数（副作用なし）として実装されています。

  利用可能なパターン:
  - :linear - 固定速度で直線移動
  - :zigzag - X軸方向に周期的な方向転換
  - :sine_wave - サイン波軌道
  - :circular - 円運動
  - :spiral - 螺旋軌道
  - :random_walk - ランダムな方向転換
  """

  alias ShooterGame.Game.Enemy

  @doc """
  パターンに基づき敵の位置を更新

  ## Parameters
    - enemy: Enemy構造体
    - current_time_ms: 現在の経過時間（ミリ秒）
    - game_width: ゲーム画面の幅
    - game_height: ゲーム画面の高さ

  ## Returns
    - 更新されたEnemy構造体（位置・速度変更済み）

  ## Examples

      iex> enemy = %Enemy{x: 100, y: 100, velocity_y: 2, movement_pattern: %{pattern_type: :linear}}
      iex> updated = MovementPattern.apply_pattern(enemy, 0, 800, 600)
      iex> updated.y
      102
  """
  @spec apply_pattern(Enemy.t(), non_neg_integer(), pos_integer(), pos_integer()) :: Enemy.t()
  def apply_pattern(enemy, current_time_ms, game_width, game_height) do
    pattern_type = enemy.movement_pattern.pattern_type
    params = enemy.movement_pattern.params
    spawn_time = enemy.movement_pattern.spawn_time

    elapsed_since_spawn = current_time_ms - spawn_time

    case pattern_type do
      :linear -> apply_linear(enemy)
      :zigzag -> apply_zigzag(enemy, elapsed_since_spawn, params)
      :sine_wave -> apply_sine_wave(enemy, elapsed_since_spawn, params)
      :circular -> apply_circular(enemy, elapsed_since_spawn, params)
      :spiral -> apply_spiral(enemy, elapsed_since_spawn, params)
      :random_walk -> apply_random_walk(enemy, elapsed_since_spawn, params)
      _ -> apply_linear(enemy)
    end
    |> clamp_to_bounds(game_width, game_height)
  end

  # 直線移動（既存の動作）
  @spec apply_linear(Enemy.t()) :: Enemy.t()
  defp apply_linear(enemy) do
    %{enemy | x: enemy.x + enemy.velocity_x, y: enemy.y + enemy.velocity_y}
  end

  # ジグザグ移動
  @spec apply_zigzag(Enemy.t(), non_neg_integer(), map()) :: Enemy.t()
  defp apply_zigzag(enemy, elapsed_ms, params) do
    amplitude = Map.get(params, :amplitude, 3.0)
    frequency = Map.get(params, :frequency, 500)

    x_offset = amplitude * :math.sin(elapsed_ms / frequency)
    %{enemy | x: enemy.x + x_offset, y: enemy.y + enemy.velocity_y}
  end

  # サイン波移動
  @spec apply_sine_wave(Enemy.t(), non_neg_integer(), map()) :: Enemy.t()
  defp apply_sine_wave(enemy, elapsed_ms, params) do
    amplitude = Map.get(params, :amplitude, 50.0)
    wavelength = Map.get(params, :wavelength, 1000)

    # 初期X座標を保持するため、パラメータから取得
    base_x = Map.get(params, :base_x, enemy.x)
    x_offset = amplitude * :math.sin(elapsed_ms / wavelength)

    %{enemy | x: base_x + x_offset, y: enemy.y + enemy.velocity_y}
  end

  # 円運動
  @spec apply_circular(Enemy.t(), non_neg_integer(), map()) :: Enemy.t()
  defp apply_circular(enemy, elapsed_ms, params) do
    radius = Map.get(params, :radius, 60.0)
    angular_velocity = Map.get(params, :angular_velocity, 0.002)
    center_x = Map.get(params, :center_x, enemy.x)
    center_y = Map.get(params, :center_y, enemy.y)

    angle = elapsed_ms * angular_velocity
    x = center_x + radius * :math.cos(angle)
    y = center_y + radius * :math.sin(angle) + enemy.velocity_y

    %{enemy | x: x, y: y}
  end

  # 螺旋軌道
  @spec apply_spiral(Enemy.t(), non_neg_integer(), map()) :: Enemy.t()
  defp apply_spiral(enemy, elapsed_ms, params) do
    initial_radius = Map.get(params, :initial_radius, 80.0)
    radius_decay = Map.get(params, :radius_decay, 0.02)
    angular_velocity = Map.get(params, :angular_velocity, 0.003)
    center_x = Map.get(params, :center_x, enemy.x)
    center_y_start = Map.get(params, :center_y, enemy.y)

    angle = elapsed_ms * angular_velocity
    radius = max(10.0, initial_radius - elapsed_ms * radius_decay)

    x = center_x + radius * :math.cos(angle)
    # Y軸は下方向に進行
    y = center_y_start + elapsed_ms * 0.05 + radius * :math.sin(angle)

    %{enemy | x: x, y: y}
  end

  # ランダムウォーク（実際には疑似ランダム: 時間ベース）
  @spec apply_random_walk(Enemy.t(), non_neg_integer(), map()) :: Enemy.t()
  defp apply_random_walk(enemy, elapsed_ms, params) do
    change_interval = Map.get(params, :change_interval, 500)
    max_velocity = Map.get(params, :max_velocity, 3.0)

    # 時間ベースのシード値を使用して方向を決定
    seed = div(elapsed_ms, change_interval)
    :rand.seed(:exsss, {seed, seed * 2, seed * 3})

    vx = (:rand.uniform() - 0.5) * max_velocity * 2
    vy = enemy.velocity_y + (:rand.uniform() - 0.5) * 1.0

    %{enemy | x: enemy.x + vx, y: enemy.y + vy}
  end

  # 境界チェック
  @spec clamp_to_bounds(Enemy.t(), pos_integer(), pos_integer()) :: Enemy.t()
  defp clamp_to_bounds(enemy, width, height) do
    clamped_x = max(0, min(enemy.x, width - enemy.width))
    clamped_y = max(-enemy.height, min(enemy.y, height))

    %{enemy | x: clamped_x, y: clamped_y}
  end

  @doc """
  パターンタイプに基づいてデフォルトパラメータを生成

  ## Examples

      iex> MovementPattern.default_params_for(:zigzag)
      %{amplitude: 3.0, frequency: 500}

      iex> MovementPattern.default_params_for(:sine_wave, 400)
      %{amplitude: 50.0, wavelength: 1000, base_x: 400}
  """
  @spec default_params_for(atom(), number() | nil) :: map()
  def default_params_for(pattern_type, base_x \\ nil)

  def default_params_for(:zigzag, _base_x) do
    %{amplitude: 3.0, frequency: 500}
  end

  def default_params_for(:sine_wave, base_x) when is_number(base_x) do
    %{amplitude: 50.0, wavelength: 1000, base_x: base_x}
  end

  def default_params_for(:sine_wave, _) do
    %{amplitude: 50.0, wavelength: 1000}
  end

  def default_params_for(:circular, base_x) when is_number(base_x) do
    %{radius: 60.0, angular_velocity: 0.002, center_x: base_x, center_y: 0}
  end

  def default_params_for(:circular, _) do
    %{radius: 60.0, angular_velocity: 0.002, center_x: 0, center_y: 0}
  end

  def default_params_for(:spiral, base_x) when is_number(base_x) do
    %{
      initial_radius: 80.0,
      radius_decay: 0.02,
      angular_velocity: 0.003,
      center_x: base_x,
      center_y: 0
    }
  end

  def default_params_for(:spiral, _) do
    %{initial_radius: 80.0, radius_decay: 0.02, angular_velocity: 0.003, center_x: 0, center_y: 0}
  end

  def default_params_for(:random_walk, _) do
    %{change_interval: 500, max_velocity: 3.0}
  end

  def default_params_for(:linear, _), do: %{}
  def default_params_for(_, _), do: %{}
end
