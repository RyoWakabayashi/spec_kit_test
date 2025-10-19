defmodule ShooterGame.Game.DifficultyLevelTest do
  use ExUnit.Case, async: true
  alias ShooterGame.Game.DifficultyLevel

  describe "new/1" do
    test "creates level 1 by default" do
      level = DifficultyLevel.new()
      assert level.level == 1
      assert level.max_enemies == 5
      assert level.spawn_interval_ms == 2000
      assert level.enemy_health_multiplier == 1.0
      assert level.fire_interval_ms == 3000
      assert level.movement_patterns == [:linear]
    end

    test "creates specific level" do
      level = DifficultyLevel.new(5)
      assert level.level == 5
      assert level.max_enemies == 13
      assert level.spawn_interval_ms == 1200
      assert level.enemy_health_multiplier == 2.5
    end

    test "clamps level to maximum 15" do
      level = DifficultyLevel.new(20)
      assert level.level == 15
    end

    test "clamps level to minimum 1" do
      level = DifficultyLevel.new(0)
      assert level.level == 1
    end
  end

  describe "next_level/1" do
    test "increments level by 1" do
      level = DifficultyLevel.new(1)
      next = DifficultyLevel.next_level(level)
      assert next.level == 2
      assert next.max_enemies == 7
    end

    test "caps at level 15" do
      level = DifficultyLevel.new(15)
      next = DifficultyLevel.next_level(level)
      assert next.level == 15
    end

    test "updates parameters correctly" do
      level = DifficultyLevel.new(2)
      next = DifficultyLevel.next_level(level)

      assert next.level == 3
      assert next.spawn_interval_ms < level.spawn_interval_ms
      assert next.max_enemies > level.max_enemies
      assert next.enemy_health_multiplier >= level.enemy_health_multiplier
    end
  end

  describe "get_config/1" do
    test "returns correct configuration for each level" do
      Enum.each(1..15, fn level_num ->
        config = DifficultyLevel.get_config(level_num)
        assert config.level == level_num
        assert config.max_enemies >= 1
        assert config.spawn_interval_ms >= 500
        assert config.enemy_health_multiplier >= 1.0
        assert is_list(config.movement_patterns)
      end)
    end

    test "level configurations show progression" do
      level1 = DifficultyLevel.get_config(1)
      level5 = DifficultyLevel.get_config(5)
      level10 = DifficultyLevel.get_config(10)

      # 難易度が上がるにつれてパラメータが厳しくなることを確認
      assert level10.spawn_interval_ms < level5.spawn_interval_ms
      assert level5.spawn_interval_ms < level1.spawn_interval_ms

      assert level10.max_enemies > level5.max_enemies
      assert level5.max_enemies > level1.max_enemies

      assert level10.enemy_health_multiplier > level5.enemy_health_multiplier
      assert level5.enemy_health_multiplier >= level1.enemy_health_multiplier
    end

    test "movement patterns expand at higher levels" do
      level1 = DifficultyLevel.get_config(1)
      level3 = DifficultyLevel.get_config(3)
      level5 = DifficultyLevel.get_config(5)

      assert length(level1.movement_patterns) == 1
      assert length(level3.movement_patterns) >= 2
      assert length(level5.movement_patterns) >= 2
    end
  end

  describe "calculate_base_health/1" do
    test "returns 1 for level 1" do
      assert DifficultyLevel.calculate_base_health(1) == 1
    end

    test "increases with level" do
      health_level_1 = DifficultyLevel.calculate_base_health(1)
      health_level_5 = DifficultyLevel.calculate_base_health(5)
      health_level_10 = DifficultyLevel.calculate_base_health(10)

      assert health_level_5 >= health_level_1
      assert health_level_10 >= health_level_5
    end

    test "never returns less than 1" do
      Enum.each(1..15, fn level ->
        health = DifficultyLevel.calculate_base_health(level)
        assert health >= 1
      end)
    end
  end

  describe "level parameters boundaries" do
    test "all levels stay within performance constraints" do
      Enum.each(1..15, fn level ->
        config = DifficultyLevel.get_config(level)

        # 敵数上限: 20体
        assert config.max_enemies <= 20

        # 出現間隔下限: 500ms
        assert config.spawn_interval_ms >= 500

        # 耐久力倍率上限: 5.0
        assert config.enemy_health_multiplier <= 5.0

        # 発射間隔下限: 1000ms
        assert config.fire_interval_ms >= 1000
      end)
    end
  end
end
