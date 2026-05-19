defmodule Lotte.Knowledge do
  @moduledoc """
  Per-tenant knowledge entries — the variable content (services, FAQs,
  Lotte-product info, etc.) that gets pushed to each tenant's Flowise
  chatflow as part of its system prompt.

  See architectural decision: https://github.com/rocketbloom/lotte/pull/3
  """
  import Ecto.Query

  alias Lotte.Knowledge.EntryModel
  alias Lotte.Repo

  def create_entry(attrs) do
    %EntryModel{}
    |> EntryModel.changeset(attrs)
    |> Repo.insert()
  end

  def get_entry(id), do: Repo.get(EntryModel, id)
  def get_entry!(id), do: Repo.get!(EntryModel, id)

  def update_entry(%EntryModel{} = entry, attrs) do
    entry
    |> EntryModel.changeset(attrs)
    |> Repo.update()
  end

  def delete_entry(%EntryModel{} = entry), do: Repo.delete(entry)

  @doc """
  Lists all entries for a tenant, oldest first.

  Options:
    * `:category` — filter by category (one of `EntryModel.categories/0`)
    * `:language` — filter by language (one of `EntryModel.languages/0`).
      When given, also matches entries with `language = "all"`.
  """
  def list_entries(tenant_id, opts \\ []) when is_binary(tenant_id) do
    EntryModel
    |> where([e], e.tenant_id == ^tenant_id)
    |> maybe_filter_category(opts[:category])
    |> maybe_filter_language(opts[:language])
    |> order_by([e], asc: e.inserted_at)
    |> Repo.all()
  end

  defp maybe_filter_category(query, nil), do: query

  defp maybe_filter_category(query, category) when is_binary(category) do
    where(query, [e], e.category == ^category)
  end

  defp maybe_filter_language(query, nil), do: query

  defp maybe_filter_language(query, language) when is_binary(language) do
    where(query, [e], e.language == ^language or e.language == "all")
  end
end
