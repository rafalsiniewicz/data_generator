defmodule DataGenerator.Repo.Migrations.AddContextToEmailVerificationTokens do
  use Ecto.Migration

  def change do
    alter table(:email_verification_tokens) do
      add :context, :string, null: false, default: "confirm_email"
    end
  end
end
