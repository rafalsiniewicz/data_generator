defmodule DataGenerator.Repo.Migrations.CreateColumns do
  use Ecto.Migration

  def change do
    create table(:columns) do
      add :name, :varchar, size: 100, null: false
      add :type_id, references(:types, on_delete: :restrict), null: false
      add :config, :jsonb, null: false, default: "{}"
      add :enum_id, references(:enums, on_delete: :nilify_all), null: true
      add :template_id, references(:templates, on_delete: :delete_all), null: false
      add :description, :varchar, size: 255, null: true

      timestamps()
    end

    create unique_index(:columns, [:template_id, :name])
    create index(:columns, [:template_id])
  end
end
