defmodule Lotte.Repo.Migrations.DropObsoleteChatHistoryTables do
  @moduledoc """
  Drops the Phoenix-native chat-history tables.

  Patient-facing chat is owned by Flowise per the architectural decision
  in https://github.com/rocketbloom/lotte/pull/3. Phoenix no longer
  stores conversations or messages locally. `Lotte.AI.ClaudeClient` is
  kept for backend AI tasks but no longer logs to `api_log`.
  """
  use Ecto.Migration

  def change do
    drop_if_exists table(:api_log)
    drop_if_exists table(:message)
    drop_if_exists table(:conversation)
  end
end
