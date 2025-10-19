defmodule ShooterGame.Game.MovementPatternTest do
  use ExUnit.Case, async: true
  alias ShooterGame.Game.{MovementPattern, Enemy}

  setup do
    base_enemy = %Enemy{
      id: "test-1",
      x: 400,
      y: 100,
      width: 40,
      height: 40,
      velocity_x: 0,
      velocity_y: 2,
      movement_pattern: %{
        pattern_type: :linear,
        params: %{},
        spawn_time: 0
      }
    }

    {:ok, base_enemy: base_enemy}
  end

  describe "apply_pattern/4 - linear" do
    test "moves enemy downward with linear pattern", %{base_enemy: enemy} do
      updated = MovementPattern.apply_pattern(enemy, 0, 800, 600)

      assert updated.y == 102
      assert updated.x == 400
    end

    test "linear pattern with velocity_x", %{base_enemy: enemy} do
      enemy = %{enemy | velocity_x: 1.5}
      updated = MovementPattern.apply_pattern(enemy, 0, 800, 600)

      assert updated.x == 401.5
      assert updated.y == 102
    end
  end

  describe "apply_pattern/4 - zigzag" do
    test "applies zigzag movement", %{base_enemy: enemy} do
      pattern = %{
        pattern_type: :zigzag,
        params: %{amplitude: 3.0, frequency: 500},
        spawn_time: 0
      }

      enemy = %{enemy | movement_pattern: pattern}

      # 時刻0
      updated_0 = MovementPattern.apply_pattern(enemy, 0, 800, 600)
      x_at_0 = updated_0.x

      # 時刻500ms (1周期の半分)
      updated_500 = MovementPattern.apply_pattern(enemy, 500, 800, 600)

      # X座標が変化していることを確認
      assert updated_500.x != x_at_0

      # Y座標は下方向に進む
      assert updated_500.y > enemy.y
    end
  end

  describe "apply_pattern/4 - sine_wave" do
    test "applies sine wave movement", %{base_enemy: enemy} do
      pattern = %{
        pattern_type: :sine_wave,
        params: %{amplitude: 50.0, wavelength: 1000, base_x: 400},
        spawn_time: 0
      }

      enemy = %{enemy | movement_pattern: pattern}

      # 時刻0 - 中心位置
      updated_0 = MovementPattern.apply_pattern(enemy, 0, 800, 600)
      assert_in_delta updated_0.x, 400, 1.0

      # 時刻250ms - 波の1/4地点
      updated_250 = MovementPattern.apply_pattern(enemy, 250, 800, 600)

      # X座標がサイン波に従って変化
      assert updated_250.x != 400

      # Y座標は下方向に進む
      assert updated_250.y > enemy.y
    end
  end

  describe "apply_pattern/4 - circular" do
    test "applies circular movement", %{base_enemy: enemy} do
      pattern = %{
        pattern_type: :circular,
        params: %{
          radius: 60.0,
          angular_velocity: 0.002,
          center_x: 400,
          center_y: 100
        },
        spawn_time: 0
      }

      enemy = %{enemy | movement_pattern: pattern}

      updated = MovementPattern.apply_pattern(enemy, 1000, 800, 600)

      # 円運動により位置が変化
      assert updated.x != enemy.x
      assert updated.y != enemy.y
    end
  end

  describe "apply_pattern/4 - spiral" do
    test "applies spiral movement", %{base_enemy: enemy} do
      pattern = %{
        pattern_type: :spiral,
        params: %{
          initial_radius: 80.0,
          radius_decay: 0.02,
          angular_velocity: 0.003,
          center_x: 400,
          center_y: 100
        },
        spawn_time: 0
      }

      enemy = %{enemy | movement_pattern: pattern}

      updated_0 = MovementPattern.apply_pattern(enemy, 0, 800, 600)
      updated_1000 = MovementPattern.apply_pattern(enemy, 1000, 800, 600)

      # 螺旋により位置が変化
      assert updated_1000.x != updated_0.x
      assert updated_1000.y > updated_0.y
    end
  end

  describe "apply_pattern/4 - random_walk" do
    test "applies random walk movement", %{base_enemy: enemy} do
      pattern = %{
        pattern_type: :random_walk,
        params: %{change_interval: 500, max_velocity: 3.0},
        spawn_time: 0
      }

      enemy = %{enemy | movement_pattern: pattern}

      updated = MovementPattern.apply_pattern(enemy, 100, 800, 600)

      # 位置が変化（ランダム性あり）
      assert is_float(updated.x)
      assert is_float(updated.y)
    end
  end

  describe "boundary clamping" do
    test "clamps x to left boundary", %{base_enemy: enemy} do
      enemy = %{enemy | x: -10, velocity_x: -5}
      updated = MovementPattern.apply_pattern(enemy, 0, 800, 600)

      assert updated.x >= 0
    end

    test "clamps x to right boundary", %{base_enemy: enemy} do
      enemy = %{enemy | x: 795, velocity_x: 10}
      updated = MovementPattern.apply_pattern(enemy, 0, 800, 600)

      # width=40 なので、x + width <= 800
      assert updated.x + updated.width <= 800
    end

    test "allows enemy slightly above screen (spawn area)", %{base_enemy: enemy} do
      enemy = %{enemy | y: -30}
      updated = MovementPattern.apply_pattern(enemy, 0, 800, 600)

      # 敵の高さ分は上に出られる（スポーン用）
      assert updated.y >= -enemy.height
    end

    test "clamps y to bottom boundary", %{base_enemy: enemy} do
      enemy = %{enemy | y: 595, velocity_y: 10}
      updated = MovementPattern.apply_pattern(enemy, 0, 800, 600)

      assert updated.y <= 600
    end
  end

  describe "default_params_for/2" do
    test "returns correct params for zigzag" do
      params = MovementPattern.default_params_for(:zigzag, nil)

      assert params.amplitude == 3.0
      assert params.frequency == 500
    end

    test "returns correct params for sine_wave with base_x" do
      params = MovementPattern.default_params_for(:sine_wave, 350)

      assert params.amplitude == 50.0
      assert params.wavelength == 1000
      assert params.base_x == 350
    end

    test "returns correct params for circular" do
      params = MovementPattern.default_params_for(:circular, 400)

      assert params.radius == 60.0
      assert params.angular_velocity == 0.002
      assert params.center_x == 400
    end

    test "returns correct params for spiral" do
      params = MovementPattern.default_params_for(:spiral, 400)

      assert params.initial_radius == 80.0
      assert params.radius_decay == 0.02
      assert params.center_x == 400
    end

    test "returns correct params for random_walk" do
      params = MovementPattern.default_params_for(:random_walk, nil)

      assert params.change_interval == 500
      assert params.max_velocity == 3.0
    end

    test "returns empty map for linear" do
      params = MovementPattern.default_params_for(:linear, nil)
      assert params == %{}
    end

    test "returns empty map for unknown pattern" do
      params = MovementPattern.default_params_for(:unknown, nil)
      assert params == %{}
    end
  end

  describe "pattern determinism" do
    test "same time produces same result for deterministic patterns", %{base_enemy: enemy} do
      pattern = %{
        pattern_type: :sine_wave,
        params: %{amplitude: 50.0, wavelength: 1000, base_x: 400},
        spawn_time: 0
      }

      enemy = %{enemy | movement_pattern: pattern}

      result1 = MovementPattern.apply_pattern(enemy, 500, 800, 600)
      result2 = MovementPattern.apply_pattern(enemy, 500, 800, 600)

      assert result1.x == result2.x
      assert result1.y == result2.y
    end
  end
end
