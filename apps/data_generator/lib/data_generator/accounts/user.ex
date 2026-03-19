defmodule DataGenerator.Accounts.User do
  @moduledoc """
  Schema for application users with authentication credentials.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :login, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string

    has_many :refresh_tokens, DataGenerator.Accounts.RefreshToken
    has_many :email_verification_tokens, DataGenerator.Accounts.EmailVerificationToken
    has_many :project_members, DataGenerator.Projects.ProjectMember
    has_many :projects, through: [:project_members, :project]
    has_many :templates, DataGenerator.Templates.Template
    has_many :enums, DataGenerator.Enums.Enum

    timestamps()
  end

  @doc """
  General-purpose changeset for updating user fields.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :login, :password])
    |> validate_email()
    |> validate_login()
    |> validate_password()
  end

  @doc """
  Changeset for user registration. Requires email, login, and password.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :login, :password])
    |> validate_required([:email, :login, :password])
    |> validate_email()
    |> validate_login()
    |> validate_password()
    |> put_password_hash()
  end

  @doc """
  Changeset for changing a user's password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_password()
    |> put_password_hash()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> unique_constraint(:email)
  end

  defp validate_login(changeset) do
    changeset
    |> validate_required([:login])
    |> validate_length(:login, min: 3, max: 100)
    |> unique_constraint(:login)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_length(:password, min: 8)
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset
end
