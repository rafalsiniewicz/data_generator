defmodule DataGenerator.Repo.Migrations.CreateEmailVerificationTokens do
  use Ecto.Migration

  def change do
    create table(:email_verification_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token_hash, :varchar, size: 255, null: false
      add :expires_at, :utc_datetime, null: false
      add :confirmed_at, :utc_datetime, null: true
      add :inserted_at, :utc_datetime, null: false
    end

    create unique_index(:email_verification_tokens, [:token_hash])
    create index(:email_verification_tokens, [:user_id])
  end
end
