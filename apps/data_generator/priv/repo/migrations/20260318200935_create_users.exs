defmodule DataGenerator.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :varchar, size: 255, null: false
      add :login, :varchar, size: 100, null: false
      add :password_hash, :varchar, size: 255, null: false

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:login])

    create constraint(:users, :email_format,
             check: "email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'"
           )
  end
end
