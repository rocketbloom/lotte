defmodule Lotte.Tenants do
  @moduledoc "Context for managing tenants and tenant-user membership."
  import Ecto.Query

  alias Ecto.Multi
  alias Lotte.Repo
  alias Lotte.Tenants.TenantModel
  alias Lotte.Users.UserModel

  def create_tenant(attrs) do
    %TenantModel{}
    |> TenantModel.changeset(attrs)
    |> Repo.insert()
  end

  def create_tenant!(attrs) do
    %TenantModel{}
    |> TenantModel.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a tenant and assigns the given user as its owner in one transaction.
  Used during onboarding when a freshly-signed-up user names their company.
  """
  def register_owner(%UserModel{} = user, attrs) do
    Multi.new()
    |> Multi.insert(:tenant, TenantModel.changeset(%TenantModel{}, attrs))
    |> Multi.update(:user, fn %{tenant: tenant} ->
      UserModel.assign_tenant_changeset(user, tenant.id, "owner")
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{tenant: tenant, user: user}} -> {:ok, %{tenant: tenant, user: user}}
      {:error, _step, changeset, _} -> {:error, changeset}
    end
  end

  def get_tenant(id), do: Repo.get(TenantModel, id)

  def get_tenant_by_slug(slug) do
    Repo.one(from t in TenantModel, where: t.slug == ^slug and t.status == "active")
  end

  def list_tenants do
    Repo.all(from t in TenantModel, where: t.status == "active")
  end

  def update_tenant(tenant, attrs) do
    tenant
    |> TenantModel.changeset(attrs)
    |> Repo.update()
  end
end
