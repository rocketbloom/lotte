defmodule LotteWeb.Plugs.Tenant do
  @moduledoc "Plug to extract tenant from subdomain and verify access"
  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    host = conn.host
    subdomain = extract_subdomain(host)

    case load_tenant(subdomain) do
      {:ok, tenant} ->
        conn
        |> assign(:current_tenant, tenant)
        |> assign(:tenant_id, tenant.id)

      :error ->
        conn
        |> put_status(404)
        |> Phoenix.Controller.put_view(html: LotteWeb.ErrorHTML)
        |> Phoenix.Controller.render("404.html")
        |> halt()
    end
  end

  defp extract_subdomain(host) do
    case String.split(host, ".") do
      [subdomain, _domain, _tld] -> subdomain
      [subdomain, _domain] -> subdomain
      [_localhost] -> nil
      _ -> nil
    end
  end

  defp load_tenant(nil) do
    # Development environment or missing subdomain
    :error
  end

  defp load_tenant("localhost") do
    # Development environment
    :error
  end

  defp load_tenant(subdomain) do
    case Lotte.Tenants.get_tenant_by_subdomain(subdomain) do
      nil ->
        Logger.warning("Tenant not found for subdomain: #{subdomain}")
        :error

      tenant ->
        {:ok, tenant}
    end
  end
end
