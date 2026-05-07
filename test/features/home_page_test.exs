defmodule LotteWeb.Features.HomePageTest do
  use LotteWeb.FeatureCase

  feature "visitor sees the Lotte landing page", %{session: session} do
    session
    |> visit("/")
    |> assert_has(Query.text("Your AI-powered paramedical assistant"))
    |> assert_has(Query.button("Start Demo"))
  end
end
