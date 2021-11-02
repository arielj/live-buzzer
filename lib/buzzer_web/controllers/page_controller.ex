defmodule BuzzerWeb.PageController do
  use BuzzerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
