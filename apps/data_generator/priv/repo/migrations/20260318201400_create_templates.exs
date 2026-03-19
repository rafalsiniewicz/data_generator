defmodule DataGenerator.Repo.Migrations.CreateTemplates do
  use Ecto.Migration

  def change do
    create table(:templates) do
      add :name, :varchar, size: 100, null: false
      add :number_of_rows, :integer, null: false
      add :user_id, references(:users, on_delete: :nilify_all), null: true
      add :description, :varchar, size: 255, null: true
      add :project_id, references(:projects, on_delete: :nilify_all), null: true

      timestamps()
    end

    create unique_index(:templates, [:user_id, :name])
    create index(:templates, [:project_id])

    create constraint(:templates, :number_of_rows_positive, check: "number_of_rows > 0")
  end
end
