defmodule DataGenerator.Release do
  @moduledoc """
  Tasks that can be run in production without Mix installed.

  Usage:

      bin/data_generator eval "DataGenerator.Release.migrate()"
      bin/data_generator eval "DataGenerator.Release.seed()"
  """

  @app :data_generator

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def seed do
    migrate()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(DataGenerator.Repo, fn _repo ->
        seed_file = Application.app_dir(@app, "priv/repo/seeds.exs")

        if File.exists?(seed_file) do
          Code.eval_file(seed_file)
        end
      end)
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.ensure_all_started(:ssl)
    Application.load(@app)
  end
end
