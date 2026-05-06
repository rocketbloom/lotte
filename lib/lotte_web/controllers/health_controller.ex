defmodule LotteWeb.HealthController do
  use LotteWeb, :controller

  def check(conn, _params) do
    json(conn, %{status: "ok", service: "lotte", version: "1"})
  end
end
