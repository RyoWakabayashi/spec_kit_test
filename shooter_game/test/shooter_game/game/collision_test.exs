defmodule ShooterGame.Game.CollisionTest do
  use ExUnit.Case, async: true

  alias ShooterGame.Game.{Collision, Player, Enemy, Bullet}

  describe "check_collision/2" do
    test "returns true when entities overlap" do
      entity1 = %{x: 100, y: 100, width: 40, height: 40}
      entity2 = %{x: 120, y: 120, width: 40, height: 40}

      assert Collision.check_collision(entity1, entity2)
    end

    test "returns false when entities do not overlap horizontally" do
      entity1 = %{x: 100, y: 100, width: 40, height: 40}
      entity2 = %{x: 200, y: 100, width: 40, height: 40}

      refute Collision.check_collision(entity1, entity2)
    end

    test "returns false when entities do not overlap vertically" do
      entity1 = %{x: 100, y: 100, width: 40, height: 40}
      entity2 = %{x: 100, y: 200, width: 40, height: 40}

      refute Collision.check_collision(entity1, entity2)
    end

    test "returns true when entities touch at edges" do
      entity1 = %{x: 100, y: 100, width: 40, height: 40}
      entity2 = %{x: 139, y: 100, width: 40, height: 40}

      assert Collision.check_collision(entity1, entity2)
    end
  end

  describe "detect_player_bullet_enemy_collisions/2" do
    test "returns collision pairs for player bullets hitting enemies" do
      bullet1 = Bullet.new(100, 100, -8, :player)
      bullet2 = Bullet.new(300, 300, -8, :player)
      enemy1 = Enemy.new(95, 95)
      enemy2 = Enemy.new(295, 295)

      bullets = [bullet1, bullet2]
      enemies = [enemy1, enemy2]

      collisions = Collision.detect_player_bullet_enemy_collisions(bullets, enemies)

      assert length(collisions) == 2
      assert {bullet1.id, enemy1.id} in collisions
      assert {bullet2.id, enemy2.id} in collisions
    end

    test "returns empty list when no collisions occur" do
      bullet = Bullet.new(100, 100, -8, :player)
      enemy = Enemy.new(300, 300)

      collisions = Collision.detect_player_bullet_enemy_collisions([bullet], [enemy])

      assert collisions == []
    end

    test "ignores enemy bullets" do
      bullet = Bullet.new(100, 100, 8, :enemy)
      enemy = Enemy.new(95, 95)

      collisions = Collision.detect_player_bullet_enemy_collisions([bullet], [enemy])

      assert collisions == []
    end
  end

  describe "detect_enemy_bullet_player_collisions/2" do
    test "returns bullet IDs for enemy bullets hitting player" do
      player = Player.new(200, 500)
      bullet1 = Bullet.new(210, 510, 8, :enemy)
      bullet2 = Bullet.new(100, 100, 8, :enemy)

      bullets = [bullet1, bullet2]

      collision_ids = Collision.detect_enemy_bullet_player_collisions(bullets, player)

      assert bullet1.id in collision_ids
      refute bullet2.id in collision_ids
    end

    test "returns empty list when no enemy bullets hit player" do
      player = Player.new(200, 500)
      bullet = Bullet.new(100, 100, 8, :enemy)

      collision_ids = Collision.detect_enemy_bullet_player_collisions([bullet], player)

      assert collision_ids == []
    end

    test "ignores player bullets" do
      player = Player.new(200, 500)
      bullet = Bullet.new(210, 510, -8, :player)

      collision_ids = Collision.detect_enemy_bullet_player_collisions([bullet], player)

      assert collision_ids == []
    end
  end

  describe "detect_enemy_player_collisions/2" do
    test "returns true when enemy collides with player" do
      player = Player.new(200, 500)
      enemy = Enemy.new(210, 510)

      assert Collision.detect_enemy_player_collisions([enemy], player)
    end

    test "returns false when no enemy collides with player" do
      player = Player.new(200, 500)
      enemy = Enemy.new(100, 100)

      refute Collision.detect_enemy_player_collisions([enemy], player)
    end

    test "returns true if any enemy collides" do
      player = Player.new(200, 500)
      enemy1 = Enemy.new(100, 100)
      enemy2 = Enemy.new(210, 510)

      assert Collision.detect_enemy_player_collisions([enemy1, enemy2], player)
    end
  end
end
