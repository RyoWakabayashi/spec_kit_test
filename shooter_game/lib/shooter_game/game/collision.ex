defmodule ShooterGame.Game.Collision do
  @moduledoc """
  Collision detection using AABB (Axis-Aligned Bounding Box).
  """

  @doc """
  Checks if two entities collide using AABB collision detection.
  """
  def check_collision(entity1, entity2) do
    x_overlap =
      entity1.x < entity2.x + entity2.width and
        entity1.x + entity1.width > entity2.x

    y_overlap =
      entity1.y < entity2.y + entity2.height and
        entity1.y + entity1.height > entity2.y

    x_overlap and y_overlap
  end

  @doc """
  Detects collisions between player bullets and enemies.
  Returns a list of {bullet_id, enemy_id} tuples for collided pairs.
  """
  def detect_player_bullet_enemy_collisions(bullets, enemies) do
    for bullet <- bullets,
        bullet.owner_type == :player,
        enemy <- enemies,
        check_collision(bullet, enemy) do
      {bullet.id, enemy.id}
    end
  end

  @doc """
  Detects collisions between enemy bullets and the player.
  Returns a list of bullet IDs that hit the player.
  """
  def detect_enemy_bullet_player_collisions(bullets, player) do
    for bullet <- bullets,
        bullet.owner_type == :enemy,
        check_collision(bullet, player) do
      bullet.id
    end
  end

  @doc """
  Detects collisions between enemies and the player.
  Returns true if any enemy collides with the player.
  """
  def detect_enemy_player_collisions(enemies, player) do
    Enum.any?(enemies, fn enemy -> check_collision(enemy, player) end)
  end
end
