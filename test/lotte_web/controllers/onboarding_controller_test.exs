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
    test "creates tenant, assigns user as owner, advances to next step", %{
      conn: conn,
      user: user
    } do
      conn = post(conn, ~p"/onboarding/company", %{"company" => %{"name" => "Acme Practice"}})
      assert redirected_to(conn) == ~p"/onboarding/about"

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

  describe "GET /onboarding/about" do
    test "redirects to company step when no tenant yet", %{conn: conn} do
      conn = get(conn, ~p"/onboarding/about")
      assert redirected_to(conn) == ~p"/onboarding/company"
    end

    test "renders the about form when tenant exists", %{conn: conn, user: user} do
      {:ok, _} = Tenants.register_owner(user, %{name: "Acme"})
      conn = get(conn, ~p"/onboarding/about")
      assert html_response(conn, 200) =~ "Tell us about your services"
    end
  end

  describe "POST /onboarding/about" do
    setup %{user: user} do
      {:ok, %{tenant: tenant}} = Tenants.register_owner(user, %{name: "Acme"})
      %{tenant: tenant}
    end

    test "saves description, services list, website url; advances to operate", %{conn: conn} do
      conn =
        post(conn, ~p"/onboarding/about", %{
          "company_profile" => %{
            "description" => "We do paramedical care",
            "services" => "Physio\nMassage\n\nPosture",
            "website_url" => "https://example.com"
          }
        })

      assert redirected_to(conn) == ~p"/onboarding/operate"

      tenant = Tenants.get_tenant(conn.assigns.current_user.tenant_id)
      assert tenant.company_profile.description == "We do paramedical care"
      assert tenant.company_profile.services == ["Physio", "Massage", "Posture"]
      assert tenant.company_profile.website_url == "https://example.com"
    end

    test "rejects malformed website_url", %{conn: conn} do
      conn =
        post(conn, ~p"/onboarding/about", %{
          "company_profile" => %{"website_url" => "not-a-url"}
        })

      assert html_response(conn, 200) =~ "must start with http"
    end
  end

  describe "POST /onboarding/operate" do
    setup %{user: user} do
      {:ok, %{tenant: tenant}} = Tenants.register_owner(user, %{name: "Acme"})
      %{tenant: tenant}
    end

    test "saves hours/address/tone and lands on dashboard", %{conn: conn} do
      conn =
        post(conn, ~p"/onboarding/operate", %{
          "company_profile" => %{
            "opening_hours" => "Mon-Fri 9-17",
            "address" => "Main St 1",
            "tone" => "warm and clear"
          }
        })

      assert redirected_to(conn) == ~p"/dashboard"

      tenant = Tenants.get_tenant(conn.assigns.current_user.tenant_id)
      assert tenant.company_profile.opening_hours == "Mon-Fri 9-17"
      assert tenant.company_profile.address == "Main St 1"
      assert tenant.company_profile.tone == "warm and clear"
    end
  end
end
