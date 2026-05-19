defmodule Lotte.AI.ClaudeClient do
  @moduledoc """
  Thin one-shot completion wrapper around the Anthropic API.

  This is for **backend** Lotte tasks that need direct LLM calls — e.g.
  website scrape → company profile extraction, intent classification,
  summaries. The patient-facing chat agent lives in Flowise (see
  https://github.com/rocketbloom/lotte/pull/3) and does NOT go through
  this module.

  Returns `{:ok, text}` or `{:error, reason}`. Conversation history is
  the caller's responsibility — pass any prior turns via the `:history`
  option as a list of `%{"role" => ..., "content" => ...}` maps.
  """
  require Logger

  @default_model "claude-3-5-sonnet-20241022"
  @default_max_tokens 1024

  @doc """
  Send a single user message to Claude with the given system prompt.

  Options:
    * `:model` — Anthropic model id (defaults to `#{@default_model}`)
    * `:max_tokens` — defaults to `#{@default_max_tokens}`
    * `:history` — list of prior turns as `%{"role" => ..., "content" => ...}`
  """
  def complete(system_prompt, user_message, opts \\ [])
      when is_binary(system_prompt) and is_binary(user_message) do
    history = Keyword.get(opts, :history, [])
    model = Keyword.get(opts, :model, @default_model)
    max_tokens = Keyword.get(opts, :max_tokens, @default_max_tokens)

    request_body = %{
      model: model,
      max_tokens: max_tokens,
      system: system_prompt,
      messages: history ++ [%{"role" => "user", "content" => user_message}]
    }

    case Anthropic.Messages.create(Anthropic.Client.new(), request_body) do
      {:ok, response} ->
        extract_response(response)

      {:error, reason} ->
        Logger.error("Claude API error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp extract_response(%{"content" => [%{"type" => "text", "text" => text} | _]}),
    do: {:ok, text}

  defp extract_response(%{"content" => [%{type: "text", text: text} | _]}),
    do: {:ok, text}

  defp extract_response(_), do: {:error, :unexpected_response_format}
end
