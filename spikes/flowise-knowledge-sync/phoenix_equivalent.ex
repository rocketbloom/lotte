defmodule Lotte.FlowiseSync do
  @moduledoc """
  Schets — zo zou Phoenix de Flowise-sync doen.
  Pseudocode, niet werkend zonder schema/migrations.

  Use case: klant past iets aan in Lotte's dashboard → Phoenix
  regenereert de system prompt → pusht 'm naar de Flowise chatflow
  van die tenant.
  """

  alias Lotte.Tenants
  alias Lotte.Knowledge  # nieuw context — bestaat nog niet

  @base_persona """
  Je bent Lotte, de AI-chatagent van <%= @tenant.name %> (<%= @tenant.website %>).
  <%= @tenant.company_description %>

  TALEN
  Begin in het Engels. Schakel over naar de taal van de bezoeker zodra die in een
  andere taal antwoordt. Schrijf idiomatisch in elke taal, geen letterlijke
  vertalingen.

  TOON
  Professioneel-warm, niveau 40–50.

  DIENSTEN
  <%= for entry <- @services do %>
  - <%= entry.title %>: <%= entry.price_range %> — <%= entry.content %>
  <% end %>

  OVER MIJZELF ALS PRODUCT
  <%= for entry <- @lotte_entries do %>
  <%= entry.content %>
  <% end %>

  AFSPRAAK INPLANNEN
  Deel de boekingslink in natuurlijke taal: <%= @tenant.calendar_url %>
  """

  @doc "Trigger handmatig of bij iedere knowledge-update via PubSub of changeset hook."
  def sync_tenant(tenant_id) do
    tenant = Tenants.get_tenant!(tenant_id)
    entries = Knowledge.list_entries_for_tenant(tenant_id)

    services = Enum.filter(entries, &(&1.category == "service"))
    lotte_entries = Enum.filter(entries, &(&1.category == "about_lotte"))

    prompt =
      EEx.eval_string(@base_persona,
        assigns: [
          tenant: tenant,
          services: services,
          lotte_entries: lotte_entries
        ]
      )

    push_to_flowise(tenant.flowise_chatflow_id, prompt)
  end

  defp push_to_flowise(chatflow_id, system_prompt) do
    base = Application.fetch_env!(:lotte, :flowise_base_url)
    api_key = Application.fetch_env!(:lotte, :flowise_api_key)

    {:ok, %{body: body}} =
      HTTPoison.get(
        "#{base}/api/v1/chatflows/#{chatflow_id}",
        [{"Authorization", "Bearer #{api_key}"}]
      )

    cf = Jason.decode!(body)
    flow_data = Jason.decode!(cf["flowData"])

    updated_nodes =
      Enum.map(flow_data["nodes"], fn
        %{"data" => %{"name" => "conversationChain"}} = node ->
          put_in(node, ["data", "inputs", "systemMessagePrompt"], system_prompt)

        node ->
          node
      end)

    updated_flow = %{flow_data | "nodes" => updated_nodes}

    HTTPoison.put(
      "#{base}/api/v1/chatflows/#{chatflow_id}",
      Jason.encode!(%{
        name: cf["name"],
        flowData: Jason.encode!(updated_flow),
        type: "CHATFLOW"
      }),
      [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ]
    )
  end
end
