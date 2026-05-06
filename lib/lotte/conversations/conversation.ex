defmodule Lotte.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversations" do
    field :external_user_id, :string
    field :status, :string, default: "active"

    belongs_to :tenant, Lotte.Tenants.Tenant, type: :binary_id
    has_many :messages, Lotte.Conversations.Message
    has_many :api_logs, Lotte.Conversations.ApiLog

    timestamps()
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:tenant_id, :external_user_id, :status])
    |> validate_required([:tenant_id, :external_user_id])
    |> validate_inclusion(:status, ["active", "archived", "closed"])
  end
end
