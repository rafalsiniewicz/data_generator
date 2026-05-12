defmodule DataGenerator.Repo.Migrations.CreateProjectMembers do
  use Ecto.Migration

  def change do
    create table(:project_members) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :is_owner, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:project_members, [:project_id, :user_id])

    create unique_index(:project_members, [:project_id],
             where: "is_owner = true",
             name: :project_members_one_owner_per_project
           )

    create index(:project_members, [:user_id])
  end
end
