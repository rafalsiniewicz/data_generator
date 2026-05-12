defmodule DataGenerator.Repo.Migrations.CreateEnumValues do
  use Ecto.Migration

  def change do
    create table(:enum_values) do
      add :enum_id, references(:enums, on_delete: :delete_all), null: false
      add :value, :varchar, size: 50, null: false

      timestamps()
    end

    create unique_index(:enum_values, [:enum_id, :value])
  end
end
