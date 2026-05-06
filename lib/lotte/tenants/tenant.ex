defmodule Lotte.Tenants.Tenant do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "tenants" do
    field :name, :string
    field :slug, :string
    field :subdomain, :string
    field :status, :string, default: "active"
    field :settings, :map, default: %{}

    has_many :conversations, Lotte.Conversations.Conversation
    has_many :api_logs, Lotte.Conversations.ApiLog

    timestamps()
  end

  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [:name, :slug, :subdomain, :status, :settings])
    |> validate_required([:name, :slug, :subdomain])
    |> unique_constraint(:slug)
    |> unique_constraint(:subdomain)
    |> validate_inclusion(:status, ["active", "inactive", "suspended"])
  end
end
