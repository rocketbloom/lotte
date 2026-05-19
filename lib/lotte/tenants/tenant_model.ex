defmodule Lotte.Tenants.TenantModel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  @max_name_length 120

  schema "tenant" do
    field :name, :string
    field :slug, :string
    field :status, :string, default: "active"
    field :settings, :map, default: %{}
    embeds_one :company_profile, Lotte.Tenants.CompanyProfileModel, on_replace: :update

    has_many :users, Lotte.Users.UserModel, foreign_key: :tenant_id

    timestamps()
  end

  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [:name, :slug, :status, :settings])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: @max_name_length)
    |> put_slug()
    |> unique_constraint(:slug)
    |> validate_inclusion(:status, ["active", "inactive", "suspended"])
  end

  def about_changeset(tenant, attrs) do
    tenant = ensure_profile(tenant)

    tenant
    |> cast(%{"company_profile" => attrs}, [])
    |> cast_embed(:company_profile,
      with: &Lotte.Tenants.CompanyProfileModel.about_changeset/2
    )
  end

  def operate_changeset(tenant, attrs) do
    tenant = ensure_profile(tenant)

    tenant
    |> cast(%{"company_profile" => attrs}, [])
    |> cast_embed(:company_profile,
      with: &Lotte.Tenants.CompanyProfileModel.operate_changeset/2
    )
  end

  defp ensure_profile(%__MODULE__{company_profile: nil} = tenant) do
    %{tenant | company_profile: %Lotte.Tenants.CompanyProfileModel{}}
  end

  defp ensure_profile(tenant), do: tenant

  defp put_slug(changeset) do
    case get_change(changeset, :slug) do
      nil ->
        case get_change(changeset, :name) do
          nil -> changeset
          name -> put_change(changeset, :slug, slugify(name))
        end

      _given ->
        changeset
    end
  end

  @doc false
  def slugify(name) do
    name
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[^a-z0-9\s-]/u, "")
    |> String.trim()
    |> String.replace(~r/[\s-]+/, "-")
  end
end
