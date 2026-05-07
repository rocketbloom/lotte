defmodule Lotte.Conversations.MessageModel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "message" do
    field :role, :string
    field :content, :string
    field :tokens_used, :integer

    belongs_to :conversation, Lotte.Conversations.ConversationModel

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:conversation_id, :role, :content, :tokens_used])
    |> validate_required([:conversation_id, :role, :content])
    |> validate_inclusion(:role, ["user", "assistant", "system"])
    |> assoc_constraint(:conversation)
  end
end
