defmodule Lotte.Repo.Migrations.AddFlowiseFieldsToTenant do
  use Ecto.Migration

  def change do
    alter table(:tenant) do
      add :flowise_chatflow_id, :string
      add :calendar_url, :string
      add :default_language, :string
    end
  end
end
