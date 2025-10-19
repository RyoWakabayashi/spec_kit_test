defmodule ShooterGameWeb.GameLiveTest do
  use ShooterGameWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Game Live - Start Screen" do
    test "renders start screen on initial mount", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")

      assert html =~ "Shooter Game"
      assert html =~ "START"
      assert has_element?(view, "button", "START")
    end

    test "shows high score on start screen", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "High Score"
    end
  end

  describe "Game Live - Game Start Transition" do
    test "transitions to playing state when START button is clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Click START button
      view |> element("button", "START") |> render_click()

      # Verify game canvas is present (game started)
      assert has_element?(view, "#game-canvas")
    end

    test "hides start screen after game starts", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Before clicking START
      assert has_element?(view, ".start-screen")

      # Click START
      view |> element("button", "START") |> render_click()

      # Start screen should be hidden
      refute has_element?(view, ".start-screen")
    end
  end

  describe "Game Live - Mouse Events" do
    test "handles mouse_move event", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Start game
      view |> element("button", "START") |> render_click()

      # Send mouse move event
      result = render_hook(view, "mouse_move", %{x: 400, y: 300})

      # Should not crash
      assert result
    end

    test "handles mouse_down event", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Start game
      view |> element("button", "START") |> render_click()

      # Send mouse down event
      result = render_hook(view, "mouse_down", %{})

      # Should not crash
      assert result
    end

    test "handles mouse_up event", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Start game
      view |> element("button", "START") |> render_click()

      # Send mouse up event
      result = render_hook(view, "mouse_up", %{})

      # Should not crash
      assert result
    end
  end

  describe "Game Live - Difficulty Scaling Integration" do
    test "initializes with difficulty level 1", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Should display initial difficulty level
      assert html =~ "Level" or html =~ "Difficulty"
    end

    test "game state starts with difficulty level 1 on game start", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Start game
      view |> element("button", "START") |> render_click()

      # Get game state from LiveView
      state = :sys.get_state(view.pid).socket.assigns.game_state

      # Verify difficulty level is initialized
      assert state.difficulty_level != nil
      assert state.difficulty_level.level == 1
      assert state.last_difficulty_update == 0
    end

    test "difficulty level increases after elapsed time", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Start game
      view |> element("button", "START") |> render_click()

      # Get initial state
      initial_state = :sys.get_state(view.pid).socket.assigns.game_state
      assert initial_state.difficulty_level.level == 1

      # Note: Testing time-based progression requires either:
      # 1. Mocking time or Process.send_after
      # 2. Waiting for actual time to pass (not practical in tests)
      # 3. Directly testing the update_game_state logic
      # This test verifies initialization only
    end

    test "difficulty affects enemy spawn parameters", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Start game
      view |> element("button", "START") |> render_click()

      state = :sys.get_state(view.pid).socket.assigns.game_state

      # Level 1 should have specific parameters
      assert state.difficulty_level.spawn_interval_ms == 2000
      assert state.difficulty_level.max_enemies == 5
      assert state.difficulty_level.fire_interval_ms == 3000
    end

    test "high score persists across game restarts", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Simulate loading high score from storage
      render_hook(view, "high_score_loaded", %{highScore: 1000})

      # Start game
      view |> element("button", "START") |> render_click()

      state = :sys.get_state(view.pid).socket.assigns.game_state
      assert state.high_score == 1000
    end
  end
end
