defmodule ShooterGameWeb.PageController do
  use ShooterGameWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
