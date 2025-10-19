defmodule ShooterGame.Game.PlayerTest do
  use ExUnit.Case, async: true

  alias ShooterGame.Game.Player

  describe "move_to/5" do
    test "moves player to specified position" do
      player = Player.new(400, 500)

      updated_player = Player.move_to(player, 300, 400, 800, 600)

      assert updated_player.x == 300
      assert updated_player.y == 400
    end

    test "clamps player position to stay within bounds - left edge" do
      player = Player.new(400, 500)

      updated_player = Player.move_to(player, -10, 300, 800, 600)

      assert updated_player.x == 0
    end

    test "clamps player position to stay within bounds - right edge" do
      player = Player.new(400, 500)

      updated_player = Player.move_to(player, 800, 300, 800, 600)

      assert updated_player.x == 800 - player.width
    end

    test "clamps player position to stay within bounds - top edge" do
      player = Player.new(400, 500)

      updated_player = Player.move_to(player, 400, -10, 800, 600)

      assert updated_player.y == 0
    end

    test "clamps player position to stay within bounds - bottom edge" do
      player = Player.new(400, 500)

      updated_player = Player.move_to(player, 400, 600, 800, 600)

      assert updated_player.y == 600 - player.height
    end
  end

  describe "firing mechanics" do
    test "start_firing/1 sets is_firing to true" do
      player = Player.new(400, 500)

      updated_player = Player.start_firing(player)

      assert updated_player.is_firing == true
    end

    test "stop_firing/1 sets is_firing to false" do
      player = Player.new(400, 500) |> Player.start_firing()

      updated_player = Player.stop_firing(player)

      assert updated_player.is_firing == false
    end

    test "can_fire?/1 returns true initially" do
      player = Player.new(400, 500)

      assert Player.can_fire?(player)
    end

    test "fire_bullet/1 creates a bullet and updates last_fire_time" do
      player = Player.new(400, 500)
      initial_fire_time = player.last_fire_time

      {:ok, bullet, updated_player} = Player.fire_bullet(player)

      assert bullet != nil
      assert bullet.owner_type == :player
      # Bullet moves upward
      assert bullet.velocity_y < 0
      assert updated_player.last_fire_time != initial_fire_time
      assert updated_player.last_fire_time != 0
    end

    test "fire_bullet/1 respects cooldown" do
      player = Player.new(400, 500)

      # Fire first bullet
      {:ok, _bullet, updated_player} = Player.fire_bullet(player)

      # Try to fire immediately again
      result = Player.fire_bullet(updated_player)

      assert result == {:error, :cooldown}
    end

    test "can fire again after cooldown period" do
      player = Player.new(400, 500)

      # Fire first bullet
      {:ok, _bullet, updated_player} = Player.fire_bullet(player)

      # Manually set last_fire_time to past cooldown
      past_time = System.monotonic_time(:millisecond) - 200
      updated_player = %{updated_player | last_fire_time: past_time}

      # Should be able to fire again
      assert Player.can_fire?(updated_player)
    end
  end
end
