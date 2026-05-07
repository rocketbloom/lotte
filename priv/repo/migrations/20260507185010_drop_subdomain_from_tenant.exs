defmodule Lotte.Repo.Migrations.DropSubdomainFromTenant do
  use Ecto.Migration

  def change do
    drop unique_index(:tenant, [:subdomain])

    alter table(:tenant) do
      remove :subdomain, :string, null: false
    end
  end
end
