defmodule Lotte.Repo.Migrations.AddCompanyProfileToTenant do
  use Ecto.Migration

  def change do
    alter table(:tenant) do
      add :company_profile, :map, default: %{}
    end
  end
end
