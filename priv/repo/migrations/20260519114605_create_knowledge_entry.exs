defmodule Lotte.Repo.Migrations.CreateKnowledgeEntry do
  use Ecto.Migration

  def change do
    create table(:knowledge_entry, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenant, type: :binary_id, on_delete: :delete_all), null: false
      add :category, :string, null: false
      add :title, :string, null: false
      add :content, :text, null: false
      add :price_range, :string
      add :language, :string, null: false, default: "all"
      timestamps()
    end

    create index(:knowledge_entry, [:tenant_id])
    create index(:knowledge_entry, [:tenant_id, :category])
    create index(:knowledge_entry, [:tenant_id, :language])
  end
end
