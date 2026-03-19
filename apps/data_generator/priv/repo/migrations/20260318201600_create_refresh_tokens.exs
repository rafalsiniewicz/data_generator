defmodule DataGenerator.Repo.Migrations.CreateRefreshTokens do
  use Ecto.Migration

  def change do
    create table(:refresh_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token_hash, :varchar, size: 255, null: false
      add :encrypted_token, :binary, null: false
      add :expires_at, :utc_datetime, null: false
      add :revoked_at, :utc_datetime, null: true
      add :replaced_by_id, references(:refresh_tokens, on_delete: :nilify_all), null: true
      add :inserted_at, :utc_datetime, null: false
    end

    create unique_index(:refresh_tokens, [:token_hash])
    create index(:refresh_tokens, [:user_id])
  end
end
