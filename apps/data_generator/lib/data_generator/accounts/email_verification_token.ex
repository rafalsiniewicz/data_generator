defmodule DataGenerator.Accounts.EmailVerificationToken do
  @moduledoc """
  Schema for email verification tokens sent to users upon registration.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "email_verification_tokens" do
    field :token_hash, :string
    field :context, :string, default: "confirm_email"
    field :expires_at, :utc_datetime
    field :confirmed_at, :utc_datetime

    belongs_to :user, DataGenerator.Accounts.User

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(email_verification_token, attrs) do
    email_verification_token
    |> cast(attrs, [:user_id, :token_hash, :context, :expires_at, :confirmed_at])
    |> validate_required([:user_id, :token_hash, :expires_at])
    |> validate_inclusion(:context, ["confirm_email", "password_reset"])
    |> foreign_key_constraint(:user_id)
  end
end
