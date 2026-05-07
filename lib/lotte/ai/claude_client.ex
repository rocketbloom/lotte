defmodule Lotte.AI.ClaudeClient do
  @moduledoc "Claude API client for Lotte"
  require Logger

  alias Lotte.Conversations

  @default_model "claude-3-5-sonnet-20241022"
  @max_tokens 1024

  def send_message(conversation_id, user_message, tenant_id) do
    with {:ok, _conversation} <- get_conversation(conversation_id, tenant_id),
         {:ok, history} <- get_conversation_history(conversation_id),
         {:ok, response} <- call_claude_api(history, user_message, tenant_id, conversation_id),
         {:ok, _} <- save_messages(conversation_id, user_message, response) do
      {:ok, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_conversation(conversation_id, tenant_id) do
    case Conversations.get_conversation(conversation_id) do
      nil ->
        {:error, :conversation_not_found}

      conversation ->
        if conversation.tenant_id == tenant_id do
          {:ok, conversation}
        else
          {:error, :unauthorized}
        end
    end
  end

  defp get_conversation_history(conversation_id) do
    case Conversations.list_messages(conversation_id) do
      messages ->
        history =
          Enum.map(messages, fn msg ->
            %{
              "role" => msg.role,
              "content" => msg.content
            }
          end)

        {:ok, history}
    end
  end

  defp call_claude_api(history, user_message, tenant_id, conversation_id) do
    messages = history ++ [%{"role" => "user", "content" => user_message}]

    request_body = %{
      model: @default_model,
      max_tokens: @max_tokens,
      system: get_system_prompt(),
      messages: messages
    }

    client = Anthropic.Client.new()

    case Anthropic.Messages.create(client, request_body) do
      {:ok, response} ->
        log_api_call(tenant_id, conversation_id, response, :success)
        extract_response(response)

      {:error, reason} ->
        Logger.error("Claude API error: #{inspect(reason)}")
        log_api_call(tenant_id, conversation_id, nil, :error, reason)
        {:error, "Failed to get response from Claude API"}
    end
  end

  defp extract_response(%{"content" => [%{"type" => "text", "text" => text} | _]}),
    do: {:ok, text}

  defp extract_response(%{"content" => content}) when is_list(content) and length(content) > 0 do
    case List.first(content) do
      %{"type" => "text", "text" => text} -> {:ok, text}
      _ -> {:error, "Unexpected response format from Claude API"}
    end
  end

  defp extract_response(_), do: {:error, "Invalid response format from Claude API"}

  defp get_system_prompt do
    """
    You are Lotte, an AI assistant for paramedical healthcare practices. Your role is to:
    1. Provide compassionate, clear support to patients
    2. Answer common questions about appointments and services
    3. Help with appointment scheduling inquiries
    4. Provide health information in an accessible way
    5. Escalate complex medical concerns to human staff

    Always be professional, empathetic, and prioritize patient safety.
    """
  end

  defp save_messages(conversation_id, user_message, assistant_response) do
    with {:ok, _} <-
           Conversations.create_message(%{
             conversation_id: conversation_id,
             role: "user",
             content: user_message
           }),
         {:ok, _} <-
           Conversations.create_message(%{
             conversation_id: conversation_id,
             role: "assistant",
             content: assistant_response
           }) do
      {:ok, :messages_saved}
    else
      {:error, reason} ->
        Logger.error("Failed to save messages: #{inspect(reason)}")
        {:error, :failed_to_save_messages}
    end
  end

  defp log_api_call(tenant_id, conversation_id, response, status, error \\ nil) do
    attrs = %{
      tenant_id: tenant_id,
      conversation_id: conversation_id,
      model: @default_model,
      input_tokens: get_input_tokens(response),
      output_tokens: get_output_tokens(response),
      total_tokens: get_total_tokens(response),
      status: Atom.to_string(status),
      error_message: error && inspect(error)
    }

    case Conversations.create_api_log(attrs) do
      {:ok, _} -> :ok
      {:error, reason} -> Logger.error("Failed to log API call: #{inspect(reason)}")
    end
  end

  defp get_input_tokens(%{"usage" => %{"input_tokens" => tokens}}), do: tokens
  defp get_input_tokens(_), do: 0

  defp get_output_tokens(%{"usage" => %{"output_tokens" => tokens}}), do: tokens
  defp get_output_tokens(_), do: 0

  defp get_total_tokens(%{
         "usage" => %{"input_tokens" => in_tokens, "output_tokens" => out_tokens}
       }) do
    in_tokens + out_tokens
  end

  defp get_total_tokens(_), do: 0
end
