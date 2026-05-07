defmodule LotteWeb.OnboardingControllerTest do
  use LotteWeb.ConnCase, async: true

  alias Lotte.Tenants
  alias Lotte.Users

  setup %{conn: conn} do
    {:ok, %{user: user}} = Users.register_with_email("owner@example.com")
    conn = Plug.Test.init_test_session(conn, %{"user_id" => user.id})
    %{conn: conn, user: user}
  end

  describe "GET /onboarding/company" do
    test "renders the form when user has no tenant", %{conn: conn} do
      conn = get(conn, ~p"/onboarding/company")
      assert html_response(conn, 200) =~ "What's your company called?"
    end

    test "redirects to dashboard when user already has a tenant", %{conn: conn, user: user} do
      {:ok, _} = Tenants.register_owner(user, %{name: "Existing Co"})
      conn = get(conn, ~p"/onboarding/company")
      assert redirected_to(conn) == ~p"/dashboard"
    end

    test "redirects to /login when not signed in", %{} do
      conn = build_conn() |> get(~p"/onboarding/company")
      assert redirected_to(conn) == ~p"/login"
    end
  end

  describe "POST /onboarding/company" do
    test "creates tenant, assigns user as owner, redirects to dashboard", %{
      conn: conn,
      user: user
    } do
      conn = post(conn, ~p"/onboarding/company", %{"company" => %{"name" => "Acme Practice"}})
      assert redirected_to(conn) == ~p"/dashboard"

      reloaded = Users.get_user!(user.id)
      assert reloaded.role == "owner"
      assert reloaded.tenant_id

      tenant = Tenants.get_tenant(reloaded.tenant_id)
      assert tenant.name == "Acme Practice"
      assert tenant.slug == "acme-practice"
    end

    test "renders error on blank name", %{conn: conn} do
      conn = post(conn, ~p"/onboarding/company", %{"company" => %{"name" => ""}})
      assert html_response(conn, 200) =~ "can&#39;t be blank"
    end
  end
end
