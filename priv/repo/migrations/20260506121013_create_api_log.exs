defmodule Lotte.Repo.Migrations.CreateApiLog do
  use Ecto.Migration

  def change do
    create table(:api_log, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, :binary_id, null: false
      add :conversation_id, references(:conversation, type: :binary_id, on_delete: :delete_all), null: true
      add :api_provider, :string, default: "claude"
      add :model, :string, null: false
      add :input_tokens, :integer, null: false
      add :output_tokens, :integer, null: false
      add :total_tokens, :integer
      add :status, :string, null: false
      add :error_message, :text
      timestamps()
    end

    create index(:api_log, [:tenant_id])
    create index(:api_log, [:conversation_id])
    create index(:api_log, [:tenant_id, :inserted_at])
  end
end
