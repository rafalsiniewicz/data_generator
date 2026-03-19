defmodule DataGenerator.Accounts do
  @moduledoc """
  The Accounts context. Manages user registration, authentication,
  email verification, and password management.
  """

  alias DataGenerator.Repo
  alias DataGenerator.Accounts.User
  alias DataGenerator.Accounts.EmailVerificationToken
  alias DataGenerator.Accounts.Auth

  @doc """
  Registers a new user with the given attributes.
  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Authenticates a user by email or login and password.
  Returns `{:ok, user}` on success, `{:error, :invalid_credentials}` on failure.
  """
  def authenticate_user(email_or_login, password) do
    user = get_user_by_email_or_login(email_or_login)

    cond do
      user && Bcrypt.verify_pass(password, user.password_hash) ->
        {:ok, user}

      user ->
        {:error, :invalid_credentials}

      true ->
        # Perform a dummy check to prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  @doc """
  Gets a single user by ID. Returns `nil` if not found or if ID is not an integer.
  """
  def get_user(id) when is_integer(id), do: Repo.get(User, id)
  def get_user(_), do: nil

  @doc """
  Gets a single user by ID. Raises if not found.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  @doc """
  Gets a user by email or login.
  """
  def get_user_by_email_or_login(identifier) do
    import Ecto.Query

    Repo.one(
      from u in User,
        where: u.email == ^identifier or u.login == ^identifier
    )
  end

  @doc """
  Changes a user's password. Requires verification of the current password.

  Expects attrs with `"current_password"` and `"password"` keys.
  """
  def change_password(user, %{"current_password" => current_password} = attrs) do
    if Bcrypt.verify_pass(current_password, user.password_hash) do
      user
      |> User.password_changeset(attrs)
      |> Repo.update()
    else
      changeset =
        user
        |> User.password_changeset(attrs)
        |> Ecto.Changeset.add_error(:current_password, "is not valid")

      {:error, changeset}
    end
  end

  def change_password(user, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> Ecto.Changeset.add_error(:current_password, "can't be blank")

    {:error, changeset}
  end

  @doc """
  Returns a changeset for tracking user registration changes.
  """
  def change_user_registration(user_or_changeset, attrs \\ %{})

  def change_user_registration(%User{} = user, attrs) do
    User.registration_changeset(user, attrs)
  end

  def change_user_registration(%Ecto.Changeset{} = changeset, attrs) do
    User.registration_changeset(changeset.data, attrs)
  end

  @doc """
  Confirms a user's email using a raw token value.
  Verifies the token exists, is not expired, and has not been used.
  """
  def confirm_email(raw_token) do
    import Ecto.Query

    token_hash = hash_token(raw_token)
    now = DateTime.utc_now()

    case Repo.one(
           from t in EmailVerificationToken,
             where: t.token_hash == ^token_hash,
             where: t.context == "confirm_email",
             where: is_nil(t.confirmed_at),
             where: t.expires_at > ^now,
             preload: [:user]
         ) do
      nil ->
        {:error, :invalid_token}

      token ->
        changeset =
          Ecto.Changeset.change(token, %{confirmed_at: DateTime.truncate(now, :second)})

        case Repo.update(changeset) do
          {:ok, _updated_token} -> {:ok, token.user}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  @doc """
  Generates an email verification token for a user.
  Returns the raw (unhashed) token that should be sent to the user.
  """
  def generate_email_token(user, context) do
    raw_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    token_hash = hash_token(raw_token)

    expires_at =
      DateTime.utc_now() |> DateTime.add(24 * 3600, :second) |> DateTime.truncate(:second)

    %EmailVerificationToken{}
    |> EmailVerificationToken.changeset(%{
      user_id: user.id,
      token_hash: token_hash,
      context: context,
      expires_at: expires_at
    })
    |> Repo.insert!()

    raw_token
  end

  @doc """
  Initiates a password reset for the given email.
  Returns `{:ok, token}` if user exists, `{:ok, nil}` otherwise (timing-safe).
  """
  def request_password_reset(email) do
    case get_user_by_email(email) do
      nil ->
        # Perform a dummy operation to prevent timing attacks
        :crypto.strong_rand_bytes(32)
        {:ok, nil}

      user ->
        token = generate_email_token(user, "password_reset")
        {:ok, token}
    end
  end

  @doc """
  Resets a user's password using a verification token.
  Revokes all refresh tokens for the user on success.
  """
  def reset_password(raw_token, attrs) do
    import Ecto.Query

    token_hash = hash_token(raw_token)
    now = DateTime.utc_now()

    case Repo.one(
           from t in EmailVerificationToken,
             where: t.token_hash == ^token_hash,
             where: t.context == "password_reset",
             where: is_nil(t.confirmed_at),
             where: t.expires_at > ^now,
             preload: [:user]
         ) do
      nil ->
        {:error, :invalid_token}

      token ->
        changeset =
          Ecto.Changeset.change(token, %{confirmed_at: DateTime.truncate(now, :second)})

        case Repo.update(changeset) do
          {:ok, _updated_token} ->
            result =
              token.user
              |> User.password_changeset(attrs)
              |> Repo.update()

            case result do
              {:ok, user} ->
                Auth.revoke_all_user_tokens(user.id)
                {:ok, user}

              error ->
                error
            end

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  defp hash_token(raw_token) do
    :crypto.hash(:sha256, raw_token)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Deletes a user and all associated data.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end
end
