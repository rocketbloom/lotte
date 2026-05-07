defmodule LotteWeb.Auth do
  @moduledoc """
  Session-side authentication helpers and plugs.

  Two session modes:
  - `:browser` — ephemeral cookie, dropped when the browser closes (used
    while the user has only an EmailIdentity, before activation)
  - `:persistent` — long-lived cookie (used after the user activates,
    i.e. has an EmailPasswordIdentity)
  """
  import Plug.Conn
  import Phoenix.Controller

  @behaviour Plug

  @impl Plug
  def init(action) when is_atom(action), do: action

  @impl Plug
  def call(conn, action), do: apply(__MODULE__, action, [conn, []])

  alias Lotte.Users
  alias Lotte.Users.UserModel

  @session_user_id_key "user_id"
  @persistent_cookie "_lotte_remember_me"
  @persistent_cookie_max_age 60 * 60 * 24 * 30
  @persistent_cookie_options [
    sign: true,
    same_site: "Lax",
    max_age: @persistent_cookie_max_age
  ]

  def log_in(conn, %UserModel{} = user, mode \\ :browser) do
    conn = put_session(conn, @session_user_id_key, user.id)

    case mode do
      :browser ->
        conn

      :persistent ->
        put_resp_cookie(conn, @persistent_cookie, user.id, @persistent_cookie_options)
    end
  end

  def log_out(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> delete_resp_cookie(@persistent_cookie)
  end

  @doc """
  Plug. Always runs. If a user is signed in (via session or persistent
  cookie) the user is assigned to `conn.assigns.current_user`.
  Sets `conn.assigns.current_user` to nil otherwise.
  """
  def fetch_current_user(conn, _opts) do
    case get_session(conn, @session_user_id_key) do
      nil ->
        conn |> restore_from_cookie() |> assign_user_or_nil()

      user_id ->
        assign(conn, :current_user, Users.get_user(user_id))
    end
  end

  defp restore_from_cookie(conn) do
    conn = fetch_cookies(conn, signed: [@persistent_cookie])

    case conn.cookies[@persistent_cookie] do
      nil ->
        conn

      user_id ->
        put_session(conn, @session_user_id_key, user_id)
    end
  end

  defp assign_user_or_nil(conn) do
    user_id = get_session(conn, @session_user_id_key)
    user = if user_id, do: Users.get_user(user_id)
    assign(conn, :current_user, user)
  end

  @doc """
  Plug. Halts with a redirect to /login if no current user.
  """
  def require_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must be signed in.")
      |> redirect(to: "/login")
      |> halt()
    end
  end
end
