defmodule Lotte.Conversations.ConversationModel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversation" do
    field :external_user_id, :string
    field :status, :string, default: "active"

    belongs_to :tenant, Lotte.Tenants.TenantModel, type: :binary_id
    has_many :messages, Lotte.Conversations.MessageModel, foreign_key: :conversation_id
    has_many :api_logs, Lotte.Conversations.ApiLogModel, foreign_key: :conversation_id

    timestamps()
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:tenant_id, :external_user_id, :status])
    |> validate_required([:tenant_id, :external_user_id])
    |> validate_inclusion(:status, ["active", "archived", "closed"])
  end
end
