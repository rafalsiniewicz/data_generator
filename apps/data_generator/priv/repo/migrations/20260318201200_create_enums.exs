defmodule DataGenerator.Repo.Migrations.CreateEnums do
  use Ecto.Migration

  def change do
    create table(:enums) do
      add :name, :varchar, size: 100, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:enums, [:user_id, :name])
    create index(:enums, [:user_id])
  end
end
