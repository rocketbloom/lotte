defmodule LotteWeb.PageController do
  use LotteWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
