defmodule LotteWeb.OnboardingController do
  use LotteWeb, :controller

  alias Lotte.Tenants
  alias Lotte.Tenants.CompanyProfileModel

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
        redirect(conn, to: ~p"/onboarding/about")

      {:error, changeset} ->
        render(conn, :company_form, error: first_error(changeset, :name), name: name)
    end
  end

  def about_form(conn, _params) do
    case load_tenant(conn) do
      {:ok, tenant} -> render(conn, :about_form, tenant: tenant, errors: %{})
      :no_tenant -> redirect(conn, to: ~p"/onboarding/company")
    end
  end

  def about_submit(conn, %{"company_profile" => attrs}) do
    case load_tenant(conn) do
      {:ok, tenant} ->
        case Tenants.update_about(tenant, attrs) do
          {:ok, _} ->
            redirect(conn, to: ~p"/onboarding/operate")

          {:error, changeset} ->
            render(conn, :about_form,
              tenant: %{tenant | company_profile: profile_from(changeset)},
              errors: profile_errors(changeset)
            )
        end

      :no_tenant ->
        redirect(conn, to: ~p"/onboarding/company")
    end
  end

  def operate_form(conn, _params) do
    case load_tenant(conn) do
      {:ok, tenant} -> render(conn, :operate_form, tenant: tenant, errors: %{})
      :no_tenant -> redirect(conn, to: ~p"/onboarding/company")
    end
  end

  def operate_submit(conn, %{"company_profile" => attrs}) do
    case load_tenant(conn) do
      {:ok, tenant} ->
        case Tenants.update_operate(tenant, attrs) do
          {:ok, _} ->
            redirect(conn, to: ~p"/dashboard")

          {:error, changeset} ->
            render(conn, :operate_form,
              tenant: %{tenant | company_profile: profile_from(changeset)},
              errors: profile_errors(changeset)
            )
        end

      :no_tenant ->
        redirect(conn, to: ~p"/onboarding/company")
    end
  end

  defp load_tenant(conn) do
    case conn.assigns.current_user.tenant_id do
      nil -> :no_tenant
      id -> {:ok, Tenants.get_tenant(id)}
    end
  end

  defp profile_from(tenant_changeset) do
    case Ecto.Changeset.get_field(tenant_changeset, :company_profile) do
      nil -> %CompanyProfileModel{}
      profile -> profile
    end
  end

  defp profile_errors(tenant_changeset) do
    case tenant_changeset.changes[:company_profile] do
      nil ->
        %{}

      embed_changeset ->
        Ecto.Changeset.traverse_errors(embed_changeset, fn {msg, opts} ->
          interpolate(msg, opts)
        end)
    end
  end

  defp first_error(changeset, field) do
    case Keyword.get(changeset.errors, field) do
      {message, opts} -> interpolate(message, opts)
      _ -> nil
    end
  end

  defp interpolate(message, opts) do
    Regex.replace(~r"%{(\w+)}", message, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end
end
