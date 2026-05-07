defmodule LotteWeb.Features.SignupAndActivateTest do
  use LotteWeb.FeatureCase

  alias Lotte.Users
  alias Lotte.Users.ActivationTokenModel

  feature "owner signs up, activates from email link, lands on dashboard", %{session: session} do
    email = "owner-#{System.unique_integer([:positive])}@example.com"

    session
    |> visit("/signup")
    |> fill_in(Query.css("[data-testid='signup-email-input']"), with: email)
    |> click(Query.button("Continue"))
    |> assert_has(Query.css("[data-testid='onboarding-company-name']"))
    |> fill_in(Query.css("[data-testid='onboarding-company-name']"), with: "Demo Practice")
    |> click(Query.button("Continue"))
    |> assert_has(Query.css("[data-testid='dashboard-status']"))
    |> assert_has(Query.css("[data-testid='dashboard-user-email']", text: email))
    |> assert_has(Query.css("[data-testid='dashboard-tenant-name']", text: "Demo Practice"))

    user = Users.get_user_by_email(email)
    refute Users.activated?(user)

    {:ok, raw_token} = Users.reissue_activation_token(user)
    new_token_record = Repo.get_by!(ActivationTokenModel, user_id: user.id)

    session
    |> visit("/activate/#{raw_token}")
    |> fill_in(Query.css("[data-testid='activation-password']"), with: "supersecret")
    |> fill_in(Query.css("[data-testid='activation-password-confirmation']"),
      with: "supersecret"
    )
    |> click(Query.css("[data-testid='activation-accept-terms']"))
    |> click(Query.css("[data-testid='activation-accept-privacy']"))
    |> click(Query.button("Activate"))
    |> assert_has(Query.css("[data-testid='dashboard-status']"))

    activated = Users.get_user_by_email(email)
    assert Users.activated?(activated)
    refute is_nil(Repo.reload!(new_token_record).consumed_at)
  end
end
