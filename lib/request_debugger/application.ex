defmodule RequestDebugger.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RequestDebuggerWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:request_debugger, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RequestDebugger.PubSub},
      RequestDebugger.RequestStore,
      # Start to serve requests, typically the last entry
      RequestDebuggerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RequestDebugger.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RequestDebuggerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
