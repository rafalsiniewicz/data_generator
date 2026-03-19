defmodule DataGenerator.Accounts.RefreshToken do
  @moduledoc """
  Schema for storing refresh tokens used in JWT-based authentication.
  Supports token rotation via the `replaced_by` self-reference.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "refresh_tokens" do
    field :token_hash, :string
    field :encrypted_token, :binary
    field :expires_at, :utc_datetime
    field :revoked_at, :utc_datetime
    field :replaced_by_id, :id

    belongs_to :user, DataGenerator.Accounts.User
    belongs_to :replaced_by, DataGenerator.Accounts.RefreshToken, define_field: false

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(refresh_token, attrs) do
    refresh_token
    |> cast(attrs, [:user_id, :token_hash, :encrypted_token, :expires_at])
    |> validate_required([:user_id, :token_hash, :encrypted_token, :expires_at])
    |> foreign_key_constraint(:user_id)
  end
end
