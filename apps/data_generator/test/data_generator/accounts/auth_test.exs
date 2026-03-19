defmodule DataGenerator.Accounts.AuthTest do
  use DataGenerator.DataCase, async: true

  alias DataGenerator.Accounts.Auth
  alias DataGenerator.Accounts.RefreshToken
  alias DataGenerator.Repo

  import Ecto.Query

  # ── Helpers ───────────────────────────────────────────────────

  defp create_user(_context) do
    user = insert(:user)
    %{user: user}
  end

  # ── create_token_pair/1 ──────────────────────────────────────

  describe "create_token_pair/1" do
    setup [:create_user]

    test "returns a valid JWT access token and refresh token", %{user: user} do
      assert {:ok, %{access_token: access_token, refresh_token: refresh_token}} =
               Auth.create_token_pair(user)

      assert is_binary(access_token)
      assert is_binary(refresh_token)

      # Access token is a valid JWT we can verify
      assert {:ok, claims} = Auth.verify_access_token(access_token)
      assert claims["sub"] == to_string(user.id)
    end

    test "stores refresh token encrypted in DB with correct hash", %{user: user} do
      {:ok, %{refresh_token: raw_refresh_token}} = Auth.create_token_pair(user)

      expected_hash =
        :crypto.hash(:sha256, raw_refresh_token)
        |> Base.encode16(case: :lower)

      token = Repo.one!(from rt in RefreshToken, where: rt.token_hash == ^expected_hash)

      assert token.user_id == user.id
      assert is_binary(token.encrypted_token)
      # Encrypted token should not equal the raw token
      assert token.encrypted_token != raw_refresh_token
      assert token.expires_at != nil
      assert is_nil(token.revoked_at)
    end

    test "token_hash is SHA-256 of the raw refresh token", %{user: user} do
      {:ok, %{refresh_token: raw_refresh_token}} = Auth.create_token_pair(user)

      expected_hash =
        :crypto.hash(:sha256, raw_refresh_token)
        |> Base.encode16(case: :lower)

      assert Repo.one(from rt in RefreshToken, where: rt.token_hash == ^expected_hash) != nil
    end
  end

  # ── verify_access_token/1 ────────────────────────────────────

  describe "verify_access_token/1" do
    setup [:create_user]

    test "valid JWT returns claims with user_id", %{user: user} do
      {:ok, %{access_token: access_token}} = Auth.create_token_pair(user)

      assert {:ok, claims} = Auth.verify_access_token(access_token)
      assert claims["sub"] == to_string(user.id)
      assert claims["exp"] > DateTime.to_unix(DateTime.utc_now())
    end

    test "expired JWT returns error" do
      # Create a JWT that has already expired
      secret =
        Application.get_env(:data_generator_web, DataGeneratorWeb.Endpoint)[:secret_key_base]

      signer = Joken.Signer.create("HS256", secret)
      now = DateTime.to_unix(DateTime.utc_now())

      claims = %{
        "sub" => "999",
        "iat" => now - 3600,
        "exp" => now - 60
      }

      {:ok, expired_token, _claims} = Joken.encode_and_sign(claims, signer)

      assert {:error, :token_expired} = Auth.verify_access_token(expired_token)
    end

    test "tampered JWT returns error" do
      assert {:error, _reason} = Auth.verify_access_token("tampered.jwt.token")
    end
  end

  # ── rotate_refresh_token/1 ───────────────────────────────────

  describe "rotate_refresh_token/1" do
    setup [:create_user]

    test "revokes old token and creates new pair", %{user: user} do
      {:ok, %{refresh_token: old_refresh_token}} = Auth.create_token_pair(user)

      assert {:ok, %{access_token: new_access, refresh_token: new_refresh}} =
               Auth.rotate_refresh_token(old_refresh_token)

      assert is_binary(new_access)
      assert is_binary(new_refresh)
      assert new_refresh != old_refresh_token

      # Old token should be revoked
      old_hash =
        :crypto.hash(:sha256, old_refresh_token)
        |> Base.encode16(case: :lower)

      old_token = Repo.one!(from rt in RefreshToken, where: rt.token_hash == ^old_hash)
      assert old_token.revoked_at != nil
    end

    test "old token has replaced_by_id set after rotation", %{user: user} do
      {:ok, %{refresh_token: old_refresh_token}} = Auth.create_token_pair(user)
      {:ok, %{refresh_token: new_refresh_token}} = Auth.rotate_refresh_token(old_refresh_token)

      old_hash =
        :crypto.hash(:sha256, old_refresh_token)
        |> Base.encode16(case: :lower)

      new_hash =
        :crypto.hash(:sha256, new_refresh_token)
        |> Base.encode16(case: :lower)

      old_token = Repo.one!(from rt in RefreshToken, where: rt.token_hash == ^old_hash)
      new_token = Repo.one!(from rt in RefreshToken, where: rt.token_hash == ^new_hash)

      assert old_token.replaced_by_id == new_token.id
    end

    test "reusing a revoked token revokes entire family", %{user: user} do
      {:ok, %{refresh_token: token_1}} = Auth.create_token_pair(user)
      {:ok, %{refresh_token: _token_2}} = Auth.rotate_refresh_token(token_1)

      # Try to reuse token_1 (already revoked)
      assert {:error, :token_reuse_detected} = Auth.rotate_refresh_token(token_1)

      # All tokens for the user should be revoked
      active_tokens =
        Repo.all(
          from rt in RefreshToken,
            where: rt.user_id == ^user.id,
            where: is_nil(rt.revoked_at)
        )

      assert active_tokens == []
    end

    test "non-existent token returns error" do
      assert {:error, :token_not_found} = Auth.rotate_refresh_token("nonexistent_token")
    end

    test "expired token returns error", %{user: user} do
      {:ok, %{refresh_token: raw_token}} = Auth.create_token_pair(user)

      # Manually expire the token
      token_hash =
        :crypto.hash(:sha256, raw_token)
        |> Base.encode16(case: :lower)

      token = Repo.one!(from rt in RefreshToken, where: rt.token_hash == ^token_hash)
      past = DateTime.utc_now() |> DateTime.add(-3600, :second) |> DateTime.truncate(:second)

      token
      |> Ecto.Changeset.change(%{expires_at: past})
      |> Repo.update!()

      assert {:error, :token_expired} = Auth.rotate_refresh_token(raw_token)
    end
  end

  # ── revoke_all_user_tokens/1 ─────────────────────────────────

  describe "revoke_all_user_tokens/1" do
    setup [:create_user]

    test "marks all user tokens as revoked", %{user: user} do
      {:ok, _} = Auth.create_token_pair(user)
      {:ok, _} = Auth.create_token_pair(user)
      {:ok, _} = Auth.create_token_pair(user)

      assert :ok = Auth.revoke_all_user_tokens(user.id)

      active_count =
        Repo.one(
          from rt in RefreshToken,
            where: rt.user_id == ^user.id,
            where: is_nil(rt.revoked_at),
            select: count()
        )

      assert active_count == 0
    end

    test "does not affect other users' tokens", %{user: user} do
      other_user = insert(:user)
      {:ok, _} = Auth.create_token_pair(user)
      {:ok, _} = Auth.create_token_pair(other_user)

      Auth.revoke_all_user_tokens(user.id)

      other_active =
        Repo.one(
          from rt in RefreshToken,
            where: rt.user_id == ^other_user.id,
            where: is_nil(rt.revoked_at),
            select: count()
        )

      assert other_active == 1
    end
  end

  # ── revoke_refresh_token/1 ──────────────────────────────────

  describe "revoke_refresh_token/1" do
    setup [:create_user]

    test "revokes a single token", %{user: user} do
      {:ok, %{refresh_token: raw_token}} = Auth.create_token_pair(user)

      assert {:ok, _} = Auth.revoke_refresh_token(raw_token)

      token_hash =
        :crypto.hash(:sha256, raw_token)
        |> Base.encode16(case: :lower)

      token = Repo.one!(from rt in RefreshToken, where: rt.token_hash == ^token_hash)
      assert token.revoked_at != nil
    end

    test "revoking an already revoked token returns ok", %{user: user} do
      {:ok, %{refresh_token: raw_token}} = Auth.create_token_pair(user)
      {:ok, _} = Auth.revoke_refresh_token(raw_token)

      assert {:ok, :already_revoked} = Auth.revoke_refresh_token(raw_token)
    end

    test "non-existent token returns error" do
      assert {:error, :token_not_found} = Auth.revoke_refresh_token("nonexistent")
    end
  end
end
