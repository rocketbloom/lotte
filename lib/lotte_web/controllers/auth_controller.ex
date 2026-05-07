defmodule LotteWeb.AuthController do
  use LotteWeb, :controller

  alias Lotte.Users
  alias LotteWeb.Auth

  def signup_form(conn, _params) do
    render(conn, :signup_form, error: nil, email: "")
  end

  def signup_submit(conn, %{"email" => email}) do
    case Users.register_with_email(email) do
      {:ok, %{user: user, token: token}} ->
        send_activation_email(conn, user, token)

        conn
        |> Auth.log_in(user, :browser)
        |> redirect(to: ~p"/onboarding/company")

      {:error, changeset} ->
        message = changeset_first_error(changeset, :email) || "We couldn't sign you up."
        render(conn, :signup_form, error: message, email: email)
    end
  end

  def activation_form(conn, %{"token" => token}) do
    render(conn, :activation_form, token: token, errors: %{})
  end

  def activation_submit(conn, %{"token" => token, "activation" => attrs}) do
    case Users.activate(token, attrs) do
      {:ok, user} ->
        conn
        |> Auth.log_in(user, :persistent)
        |> put_flash(:info, "Account activated.")
        |> redirect(to: ~p"/dashboard")

      {:error, :invalid_token} ->
        conn
        |> put_flash(:error, "This activation link is invalid or expired.")
        |> redirect(to: ~p"/")

      {:error, changeset} ->
        render(conn, :activation_form, token: token, errors: errors_map(changeset))
    end
  end

  def login_form(conn, _params) do
    render(conn, :login_form, error: nil, email: "")
  end

  def login_submit(conn, %{"email" => email, "password" => password}) do
    case Users.authenticate_with_password(email, password) do
      nil ->
        render(conn, :login_form, error: "Invalid email or password.", email: email)

      user ->
        conn
        |> Auth.log_in(user, :persistent)
        |> redirect(to: ~p"/dashboard")
    end
  end

  def logout(conn, _params) do
    conn
    |> Auth.log_out()
    |> redirect(to: ~p"/")
  end

  defp send_activation_email(conn, user, token) do
    url_for_token = fn t -> url(conn, ~p"/activate/#{t}") end
    Users.deliver_activation_email(user, token, url_for_token)
  end

  defp changeset_first_error(changeset, field) do
    case Keyword.get(changeset.errors, field) do
      {message, opts} -> interpolate_message(message, opts)
      _ -> nil
    end
  end

  defp errors_map(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      interpolate_message(message, opts)
    end)
  end

  defp interpolate_message(message, opts) do
    Regex.replace(~r"%{(\w+)}", message, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end
end
