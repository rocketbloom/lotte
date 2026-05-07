defmodule LotteWeb.AuthControllerTest do
  use LotteWeb.ConnCase, async: true

  alias Lotte.Users

  describe "GET /signup" do
    test "renders the form", %{conn: conn} do
      conn = get(conn, ~p"/signup")
      assert html_response(conn, 200) =~ "Get started with Lotte"
    end
  end

  describe "POST /signup" do
    test "creates user, logs in, redirects to dashboard", %{conn: conn} do
      conn = post(conn, ~p"/signup", %{"email" => "newuser@example.com"})
      assert redirected_to(conn) == ~p"/dashboard"
      assert get_session(conn, "user_id")
      assert Users.get_user_by_email("newuser@example.com")
    end

    test "renders errors on invalid email", %{conn: conn} do
      conn = post(conn, ~p"/signup", %{"email" => "not-an-email"})
      response = html_response(conn, 200)
      assert response =~ "must have the @ sign"
      refute get_session(conn, "user_id")
    end
  end

  describe "GET /activate/:token" do
    test "shows the activation form", %{conn: conn} do
      {:ok, %{token: token}} = Users.register_with_email("a@example.com")
      conn = get(conn, ~p"/activate/#{token}")
      assert html_response(conn, 200) =~ "Activate your account"
    end
  end

  describe "POST /activate/:token" do
    setup do
      {:ok, %{user: user, token: token}} = Users.register_with_email("activate@example.com")
      %{user: user, token: token}
    end

    test "activates and logs in on success", %{conn: conn, token: token} do
      attrs = %{
        "password" => "supersecret",
        "password_confirmation" => "supersecret",
        "accept_terms" => "true",
        "accept_privacy" => "true"
      }

      conn = post(conn, ~p"/activate/#{token}", %{"activation" => attrs})
      assert redirected_to(conn) == ~p"/dashboard"
      assert get_session(conn, "user_id")
    end

    test "shows errors on bad input", %{conn: conn, token: token} do
      attrs = %{
        "password" => "short",
        "password_confirmation" => "different",
        "accept_terms" => "false",
        "accept_privacy" => "false"
      }

      conn = post(conn, ~p"/activate/#{token}", %{"activation" => attrs})
      response = html_response(conn, 200)
      assert response =~ "you must accept the terms"
    end

    test "redirects to / on invalid token", %{conn: conn} do
      attrs = %{
        "password" => "supersecret",
        "password_confirmation" => "supersecret",
        "accept_terms" => "true",
        "accept_privacy" => "true"
      }

      conn = post(conn, ~p"/activate/garbage", %{"activation" => attrs})
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "POST /login" do
    setup do
      {:ok, %{user: user, token: token}} = Users.register_with_email("loginuser@example.com")

      attrs = %{
        "password" => "supersecret",
        "password_confirmation" => "supersecret",
        "accept_terms" => "true",
        "accept_privacy" => "true"
      }

      {:ok, _} = Users.activate(token, attrs)
      %{user: user}
    end

    test "logs the user in with valid creds", %{conn: conn} do
      conn =
        post(conn, ~p"/login", %{"email" => "loginuser@example.com", "password" => "supersecret"})

      assert redirected_to(conn) == ~p"/dashboard"
      assert get_session(conn, "user_id")
    end

    test "shows error on bad password", %{conn: conn} do
      conn =
        post(conn, ~p"/login", %{"email" => "loginuser@example.com", "password" => "wrong"})

      assert html_response(conn, 200) =~ "Invalid email or password"
      refute get_session(conn, "user_id")
    end
  end

  describe "DELETE /logout" do
    test "clears the session", %{conn: conn} do
      {:ok, %{user: user}} = Users.register_with_email("logout@example.com")
      conn = conn |> Plug.Test.init_test_session(%{"user_id" => user.id})

      conn = delete(conn, ~p"/logout")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, "user_id")
    end
  end

  describe "GET /dashboard" do
    test "redirects to /login when not signed in", %{conn: conn} do
      conn = get(conn, ~p"/dashboard")
      assert redirected_to(conn) == ~p"/login"
    end

    test "renders when signed in", %{conn: conn} do
      {:ok, %{user: user}} = Users.register_with_email("dash@example.com")
      conn = conn |> Plug.Test.init_test_session(%{"user_id" => user.id}) |> get(~p"/dashboard")
      assert html_response(conn, 200) =~ "dash@example.com"
    end
  end
end
