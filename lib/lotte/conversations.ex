defmodule Lotte.Conversations do
  @moduledoc "Context for managing conversations and messages"
  import Ecto.Query
  alias Lotte.Repo
  alias Lotte.Conversations.{Conversation, Message, ApiLog}

  def create_conversation(attrs) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  def get_conversation(id) do
    Repo.get(Conversation, id)
  end

  def get_or_create_conversation(tenant_id, external_user_id) do
    case Repo.one(from c in Conversation, where: c.tenant_id == ^tenant_id and c.external_user_id == ^external_user_id and c.status == "active") do
      nil ->
        create_conversation(%{
          tenant_id: tenant_id,
          external_user_id: external_user_id,
          status: "active"
        })
      conversation ->
        {:ok, conversation}
    end
  end

  def list_conversations(tenant_id, opts \\ []) do
    status = Keyword.get(opts, :status, "active")

    from(c in Conversation,
      where: c.tenant_id == ^tenant_id and c.status == ^status,
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
  end

  def list_conversations_for_tenant(tenant_id) do
    from(c in Conversation, where: c.tenant_id == ^tenant_id and c.status == "active")
    |> Repo.all()
  end

  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def list_messages(conversation_id) do
    from(m in Message, where: m.conversation_id == ^conversation_id, order_by: m.inserted_at)
    |> Repo.all()
  end

  def create_api_log(attrs) do
    %ApiLog{}
    |> ApiLog.changeset(attrs)
    |> Repo.insert()
  end

  def get_api_usage(tenant_id, days \\ 30) do
    cutoff = NaiveDateTime.add(NaiveDateTime.utc_now(), -days * 86400)
    from(a in ApiLog,
      where: a.tenant_id == ^tenant_id and a.inserted_at >= ^cutoff and a.status == "success",
      select: %{
        total_tokens: fragment("COALESCE(SUM(total_tokens), 0)"),
        total_calls: count(a.id),
        avg_tokens: fragment("COALESCE(AVG(total_tokens), 0)")
      }
    )
    |> Repo.one()
  end

  def update_conversation_status(conversation_id, status) do
    conversation = Repo.get!(Conversation, conversation_id)
    Conversation.changeset(conversation, %{status: status})
    |> Repo.update()
  end
end
