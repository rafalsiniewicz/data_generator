defmodule DataGenerator.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :varchar, size: 100, null: false

      timestamps()
    end
  end
end
