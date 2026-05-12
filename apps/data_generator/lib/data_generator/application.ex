defmodule DataGenerator.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DataGenerator.Repo,
      {DNSCluster, query: Application.get_env(:data_generator, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DataGenerator.PubSub},
      {Task.Supervisor, name: DataGenerator.Generator.TaskSupervisor},
      {DynamicSupervisor, name: DataGenerator.Generator.JobSupervisor, strategy: :one_for_one}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: DataGenerator.Supervisor)
  end
end
