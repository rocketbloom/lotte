defmodule LotteWeb.OnboardingController do
  use LotteWeb, :controller

  alias Lotte.Tenants

  def company_form(conn, _params) do
    user = conn.assigns.current_user

    if user.tenant_id do
      redirect(conn, to: ~p"/dashboard")
    else
      render(conn, :company_form, error: nil, name: "")
    end
  end

  def company_submit(conn, %{"company" => %{"name" => name}}) do
    user = conn.assigns.current_user

    case Tenants.register_owner(user, %{name: name}) do
      {:ok, _} ->
        redirect(conn, to: ~p"/dashboard")

      {:error, changeset} ->
        message =
          case Keyword.get(changeset.errors, :name) do
            {msg, opts} -> interpolate(msg, opts)
            _ -> "Couldn't create your company."
          end

        render(conn, :company_form, error: message, name: name)
    end
  end

  defp interpolate(message, opts) do
    Regex.replace(~r"%{(\w+)}", message, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end
end
