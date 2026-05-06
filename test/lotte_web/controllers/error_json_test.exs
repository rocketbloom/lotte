defmodule LotteWeb.ErrorJSONTest do
  use LotteWeb.ConnCase, async: true

  test "renders 404" do
    assert LotteWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert LotteWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
