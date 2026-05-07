defmodule LotteWeb.PageControllerTest do
  use LotteWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Your AI-powered paramedical assistant"
  end
end
