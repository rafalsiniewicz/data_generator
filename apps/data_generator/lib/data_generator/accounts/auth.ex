defmodule DataGenerator.Accounts.Auth do
  @moduledoc """
  Token management for JWT-based authentication.

  Handles creation of access/refresh token pairs, token rotation,
  revocation, and verification.
  """

  alias DataGenerator.Repo
  alias DataGenerator.Accounts.RefreshToken

  @access_token_ttl_seconds 15 * 60
  @refresh_token_ttl_seconds 30 * 24 * 3600

  @doc """
  Creates a JWT access token and a refresh token for the given user.

  Returns `{:ok, %{access_token: ..., refresh_token: ...}}`.
  """
  def create_token_pair(user) do
    access_token = generate_access_token(user)
    raw_refresh_token = generate_raw_refresh_token()
    token_hash = hash_token(raw_refresh_token)
    encrypted_token = DataGenerator.Vault.encrypt!(raw_refresh_token)

    expires_at =
      DateTime.utc_now()
      |> DateTime.add(@refresh_token_ttl_seconds, :second)
      |> DateTime.truncate(:second)

    %RefreshToken{}
    |> RefreshToken.changeset(%{
      user_id: user.id,
      token_hash: token_hash,
      encrypted_token: encrypted_token,
      expires_at: expires_at
    })
    |> Repo.insert!()

    {:ok, %{access_token: access_token, refresh_token: raw_refresh_token}}
  end

  @doc """
  Rotates a refresh token. The old token is revoked and a new token pair is issued.

  If a revoked token is reused, the entire token family is revoked for security.

  Returns `{:ok, %{access_token: ..., refresh_token: ...}}` or `{:error, reason}`.
  """
  def rotate_refresh_token(raw_refresh_token) do
    import Ecto.Query

    token_hash = hash_token(raw_refresh_token)
    now = DateTime.utc_now()

    case Repo.one(from rt in RefreshToken, where: rt.token_hash == ^token_hash, preload: [:user]) do
      nil ->
        {:error, :token_not_found}

      %RefreshToken{revoked_at: revoked_at} = token when not is_nil(revoked_at) ->
        # Revoked token reuse detected — revoke entire family
        revoke_all_user_tokens(token.user_id)
        {:error, :token_reuse_detected}

      %RefreshToken{} = old_token ->
        if DateTime.compare(old_token.expires_at, now) != :gt do
          {:error, :token_expired}
        else
          Repo.transaction(fn ->
            # Revoke the old token
            old_token
            |> Ecto.Changeset.change(%{revoked_at: DateTime.truncate(now, :second)})
            |> Repo.update!()

            # Create new pair
            {:ok, new_pair} = create_token_pair(old_token.user)

            # Link old token to the new one
            new_token_hash = hash_token(new_pair.refresh_token)

            new_token =
              Repo.one!(from rt in RefreshToken, where: rt.token_hash == ^new_token_hash)

            old_token
            |> Ecto.Changeset.change(%{replaced_by_id: new_token.id})
            |> Repo.update!()

            new_pair
          end)
        end
    end
  end

  @doc """
  Revokes all refresh tokens for a given user.
  """
  def revoke_all_user_tokens(user_id) do
    import Ecto.Query

    now = DateTime.truncate(DateTime.utc_now(), :second)

    from(rt in RefreshToken,
      where: rt.user_id == ^user_id,
      where: is_nil(rt.revoked_at)
    )
    |> Repo.update_all(set: [revoked_at: now])

    :ok
  end

  @doc """
  Verifies a JWT access token string.

  Returns `{:ok, claims}` or `{:error, reason}`.
  """
  def verify_access_token(token_string) do
    case Joken.verify(token_string, signer()) do
      {:ok, claims} ->
        if claims["exp"] && claims["exp"] > DateTime.to_unix(DateTime.utc_now()) do
          {:ok, claims}
        else
          {:error, :token_expired}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Revokes a single refresh token by its raw value.
  """
  def revoke_refresh_token(raw_token) do
    import Ecto.Query

    token_hash = hash_token(raw_token)
    now = DateTime.truncate(DateTime.utc_now(), :second)

    case Repo.one(from rt in RefreshToken, where: rt.token_hash == ^token_hash) do
      nil ->
        {:error, :token_not_found}

      %RefreshToken{revoked_at: revoked_at} when not is_nil(revoked_at) ->
        {:ok, :already_revoked}

      token ->
        token
        |> Ecto.Changeset.change(%{revoked_at: now})
        |> Repo.update()
    end
  end

  # -- Private helpers --

  defp generate_access_token(user) do
    now = DateTime.to_unix(DateTime.utc_now())

    claims = %{
      "sub" => to_string(user.id),
      "iat" => now,
      "exp" => now + @access_token_ttl_seconds
    }

    {:ok, token, _claims} = Joken.encode_and_sign(claims, signer())
    token
  end

  defp generate_raw_refresh_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  defp hash_token(raw_token) do
    :crypto.hash(:sha256, raw_token)
    |> Base.encode16(case: :lower)
  end

  defp signer do
    secret =
      Application.get_env(:data_generator_web, DataGeneratorWeb.Endpoint)[:secret_key_base]

    Joken.Signer.create("HS256", secret)
  end
end
