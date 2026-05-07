defmodule Lotte.Conversations.ApiLogModel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "api_log" do
    field :tenant_id, :binary_id
    field :api_provider, :string, default: "claude"
    field :model, :string
    field :input_tokens, :integer
    field :output_tokens, :integer
    field :total_tokens, :integer
    field :status, :string
    field :error_message, :string

    belongs_to :conversation, Lotte.Conversations.ConversationModel, type: :binary_id

    timestamps()
  end

  def changeset(api_log, attrs) do
    api_log
    |> cast(attrs, [:tenant_id, :conversation_id, :api_provider, :model, :input_tokens, :output_tokens, :total_tokens, :status, :error_message])
    |> validate_required([:tenant_id, :model, :input_tokens, :output_tokens, :status])
    |> validate_inclusion(:status, ["success", "error", "rate_limited"])
  end
end
