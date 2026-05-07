defmodule Lotte.Repo.Migrations.CreateUserAndIdentities do
  use Ecto.Migration

  def change do
    create table(:user, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :tenant_id, references(:tenant, type: :binary_id, on_delete: :nilify_all)
      add :role, :string
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:user, [:email])
    create index(:user, [:tenant_id])

    create table(:email_identity, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:user, type: :binary_id, on_delete: :delete_all), null: false
      add :validation_data, :map
      add :validated_at, :naive_datetime
      timestamps()
    end

    create unique_index(:email_identity, [:user_id])

    create table(:email_password_identity, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:user, type: :binary_id, on_delete: :delete_all), null: false
      add :hashed_password, :string, null: false
      add :terms_accepted_at, :naive_datetime, null: false
      add :privacy_accepted_at, :naive_datetime, null: false
      timestamps()
    end

    create unique_index(:email_password_identity, [:user_id])

    create table(:activation_token, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:user, type: :binary_id, on_delete: :delete_all), null: false
      add :token_hash, :string, null: false
      add :expires_at, :naive_datetime, null: false
      add :consumed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:activation_token, [:user_id])
    create unique_index(:activation_token, [:token_hash])
  end
end
