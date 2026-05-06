defmodule Lotte.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LotteWeb.Telemetry,
      Lotte.Repo,
      {DNSCluster, query: Application.get_env(:lotte, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Lotte.PubSub},
      # Start a worker by calling: Lotte.Worker.start_link(arg)
      # {Lotte.Worker, arg},
      # Start to serve requests, typically the last entry
      LotteWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lotte.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LotteWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
