defmodule Lotte.Repo.Migrations.CreateTenants do
  use Ecto.Migration

  def change do
    create table(:tenants, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :subdomain, :string, null: false
      add :status, :string, default: "active"
      add :settings, :map, default: %{}
      timestamps()
    end

    create unique_index(:tenants, [:slug])
    create unique_index(:tenants, [:subdomain])
  end
end
