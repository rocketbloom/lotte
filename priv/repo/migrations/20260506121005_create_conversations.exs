defmodule Lotte.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, :binary_id, null: false
      add :external_user_id, :string, null: false
      add :status, :string, default: "active"
      timestamps()
    end

    create index(:conversations, [:tenant_id])
    create index(:conversations, [:external_user_id])
    create index(:conversations, [:tenant_id, :external_user_id])

    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :conversation_id, references(:conversations, type: :binary_id, on_delete: :delete_all), null: false
      add :role, :string, null: false
      add :content, :text, null: false
      add :tokens_used, :integer
      timestamps()
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:role])
  end
end
