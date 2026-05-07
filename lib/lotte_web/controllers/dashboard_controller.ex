defmodule LotteWeb.DashboardController do
  use LotteWeb, :controller

  def index(conn, _params) do
    render(conn, :index, user: conn.assigns.current_user)
  end
end
