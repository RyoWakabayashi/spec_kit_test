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
      {:ok, view, html} = live(conn, "/")

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
end
