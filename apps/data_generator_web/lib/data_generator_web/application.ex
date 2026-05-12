defmodule DataGeneratorWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DataGeneratorWeb.Telemetry,
      # Start a worker by calling: DataGeneratorWeb.Worker.start_link(arg)
      # {DataGeneratorWeb.Worker, arg},
      # Start to serve requests, typically the last entry
      DataGeneratorWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DataGeneratorWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DataGeneratorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
