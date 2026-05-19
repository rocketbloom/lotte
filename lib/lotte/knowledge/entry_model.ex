defmodule Lotte.Knowledge.EntryModel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @categories ~w(service about_lotte faq general)
  @languages ~w(nl en all)

  schema "knowledge_entry" do
    field :category, :string
    field :title, :string
    field :content, :string
    field :price_range, :string
    field :language, :string, default: "all"

    belongs_to :tenant, Lotte.Tenants.TenantModel

    timestamps()
  end

  def categories, do: @categories
  def languages, do: @languages

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:tenant_id, :category, :title, :content, :price_range, :language])
    |> validate_required([:tenant_id, :category, :title, :content])
    |> validate_inclusion(:category, @categories)
    |> validate_inclusion(:language, @languages)
    |> assoc_constraint(:tenant)
  end
end
