defmodule LotteWeb.HealthControllerTest do
  use LotteWeb.ConnCase, async: true

  test "GET /health/ returns ok JSON", %{conn: conn} do
    conn = get(conn, ~p"/health/")
    assert json_response(conn, 200) == %{"status" => "ok", "service" => "lotte", "version" => "1"}
  end
end
