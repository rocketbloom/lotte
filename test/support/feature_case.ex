defmodule LotteWeb.FeatureCase do
  @moduledoc """
  Test case for browser-driven feature tests using Wallaby.

  Feature tests run a real Chrome browser against the running Phoenix
  endpoint and exercise the application from the user's perspective.

  ## Usage

      use LotteWeb.FeatureCase

      feature "title", %{session: session} do
        session
        |> visit("/")
        |> assert_has(Query.text("Lotte"))
      end

  ## Running

  Feature tests require ChromeDriver:

      # macOS
      brew install --cask chromedriver

      # Run all feature tests (headless)
      mix test test/features

      # Visible browser for debugging
      WALLABY_HEADLESS=false mix test test/features

  Each test gets its own browser session and Ecto sandbox via the
  `Wallaby.Feature` macro — no manual setup needed here.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.Feature

      import Wallaby.Query
      alias Lotte.Repo
    end
  end
end
