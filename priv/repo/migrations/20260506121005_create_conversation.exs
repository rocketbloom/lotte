defmodule Lotte.Repo.Migrations.CreateConversation do
  use Ecto.Migration

  def change do
    create table(:conversation, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, :binary_id, null: false
      add :external_user_id, :string, null: false
      add :status, :string, default: "active"
      timestamps()
    end

    create index(:conversation, [:tenant_id])
    create index(:conversation, [:external_user_id])
    create index(:conversation, [:tenant_id, :external_user_id])

    create table(:message, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :conversation_id, references(:conversation, type: :binary_id, on_delete: :delete_all),
        null: false

      add :role, :string, null: false
      add :content, :text, null: false
      add :tokens_used, :integer
      timestamps()
    end

    create index(:message, [:conversation_id])
    create index(:message, [:role])
  end
end
