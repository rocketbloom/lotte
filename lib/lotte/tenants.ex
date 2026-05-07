defmodule Lotte.Tenants do
  @moduledoc "Context for managing tenants"
  import Ecto.Query
  alias Lotte.Repo
  alias Lotte.Tenants.TenantModel

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

  def get_tenant(id) do
    Repo.get(TenantModel, id)
  end

  def get_tenant_by_subdomain(subdomain) do
    Repo.one(from t in TenantModel, where: t.subdomain == ^subdomain and t.status == "active")
  end

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
