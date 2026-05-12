defmodule DataGenerator.AccountsTest do
  use DataGenerator.DataCase, async: true

  alias DataGenerator.Accounts
  alias DataGenerator.Accounts.User

  # ── Helpers ───────────────────────────────────────────────────

  defp create_user(_context) do
    user = insert(:user) |> confirm_user_email()
    %{user: user}
  end

  # ── register_user/1 ──────────────────────────────────────────

  describe "register_user/1" do
    test "valid attrs creates user" do
      attrs = %{
        "email" => "test@example.com",
        "login" => "testuser",
        "password" => "Password123!"
      }

      assert {:ok, %User{} = user} = Accounts.register_user(attrs)
      assert user.email == "test@example.com"
      assert user.login == "testuser"
      assert user.password_hash != nil
      # virtual field should not be persisted
      assert user.password == nil
    end

    test "duplicate email fails" do
      insert(:user, email: "dup@example.com")

      attrs = %{
        "email" => "dup@example.com",
        "login" => "other_user",
        "password" => "Password123!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{email: _} = errors_on(changeset)
    end

    test "duplicate login fails" do
      insert(:user, login: "dupuser")

      attrs = %{
        "email" => "other@example.com",
        "login" => "dupuser",
        "password" => "Password123!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{login: _} = errors_on(changeset)
    end

    test "invalid email format fails" do
      attrs = %{
        "email" => "not-an-email",
        "login" => "validuser",
        "password" => "Password123!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{email: _} = errors_on(changeset)
    end

    test "short password fails" do
      attrs = %{
        "email" => "short@example.com",
        "login" => "shortpw",
        "password" => "short"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{password: _} = errors_on(changeset)
    end

    test "missing fields fail" do
      assert {:error, changeset} = Accounts.register_user(%{})
      errors = errors_on(changeset)
      assert Map.has_key?(errors, :email)
      assert Map.has_key?(errors, :login)
      assert Map.has_key?(errors, :password)
    end
  end

  # ── authenticate_user/2 ─────────────────────────────────────

  describe "authenticate_user/2" do
    setup [:create_user]

    test "valid email + password succeeds", %{user: user} do
      assert {:ok, authenticated} = Accounts.authenticate_user(user.email, "Password123!")
      assert authenticated.id == user.id
    end

    test "valid login + password succeeds", %{user: user} do
      assert {:ok, authenticated} = Accounts.authenticate_user(user.login, "Password123!")
      assert authenticated.id == user.id
    end

    test "wrong password fails", %{user: user} do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user(user.email, "WrongPassword!")
    end

    test "non-existent user fails" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user("nobody@example.com", "Password123!")
    end
  end

  # ── get_user/1 ───────────────────────────────────────────────

  describe "get_user/1" do
    setup [:create_user]

    test "returns user for valid id", %{user: user} do
      assert %User{} = Accounts.get_user(user.id)
    end

    test "returns nil for non-existent id" do
      assert Accounts.get_user(0) == nil
    end

    test "returns nil for non-integer" do
      assert Accounts.get_user("not_an_id") == nil
    end
  end

  # ── get_user!/1 ──────────────────────────────────────────────

  describe "get_user!/1" do
    setup [:create_user]

    test "returns user", %{user: user} do
      assert %User{} = Accounts.get_user!(user.id)
    end

    test "raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(0)
      end
    end
  end

  # ── get_user_by_email/1 ─────────────────────────────────────

  describe "get_user_by_email/1" do
    setup [:create_user]

    test "returns user for valid email", %{user: user} do
      assert %User{id: id} = Accounts.get_user_by_email(user.email)
      assert id == user.id
    end

    test "returns nil for unknown email" do
      assert Accounts.get_user_by_email("nobody@nowhere.com") == nil
    end
  end

  # ── get_user_by_email_or_login/1 ─────────────────────────────

  describe "get_user_by_email_or_login/1" do
    setup [:create_user]

    test "finds by email", %{user: user} do
      assert %User{id: id} = Accounts.get_user_by_email_or_login(user.email)
      assert id == user.id
    end

    test "finds by login", %{user: user} do
      assert %User{id: id} = Accounts.get_user_by_email_or_login(user.login)
      assert id == user.id
    end

    test "returns nil for unknown identifier" do
      assert Accounts.get_user_by_email_or_login("nobody") == nil
    end
  end

  # ── change_password/2 ───────────────────────────────────────

  describe "change_password/2" do
    setup [:create_user]

    test "changes password with correct current password", %{user: user} do
      attrs = %{"current_password" => "Password123!", "password" => "NewPassword456!"}

      assert {:ok, updated} = Accounts.change_password(user, attrs)
      assert updated.password_hash != user.password_hash
    end

    test "fails with wrong current password", %{user: user} do
      attrs = %{"current_password" => "WrongPassword!", "password" => "NewPassword456!"}

      assert {:error, changeset} = Accounts.change_password(user, attrs)
      assert %{current_password: _} = errors_on(changeset)
    end

    test "fails without current_password key", %{user: user} do
      attrs = %{"password" => "NewPassword456!"}

      assert {:error, changeset} = Accounts.change_password(user, attrs)
      assert %{current_password: _} = errors_on(changeset)
    end
  end

  # ── change_user_registration/2 ──────────────────────────────

  describe "change_user_registration/2" do
    test "returns a changeset from user struct" do
      changeset = Accounts.change_user_registration(%User{})
      assert %Ecto.Changeset{} = changeset
    end

    test "returns a changeset from existing changeset" do
      changeset = Accounts.change_user_registration(%User{})
      changeset2 = Accounts.change_user_registration(changeset)
      assert %Ecto.Changeset{} = changeset2
    end
  end

  # ── generate_email_token/2 ──────────────────────────────────

  describe "generate_email_token/2" do
    setup [:create_user]

    test "returns a raw token string", %{user: user} do
      token = Accounts.generate_email_token(user, "confirm_email")
      assert is_binary(token)
      assert byte_size(token) > 0
    end
  end

  # ── confirm_email/1 ─────────────────────────────────────────

  describe "confirm_email/1" do
    setup [:create_user]

    test "confirms with valid token", %{user: user} do
      token = Accounts.generate_email_token(user, "confirm_email")
      assert {:ok, confirmed_user} = Accounts.confirm_email(token)
      assert confirmed_user.id == user.id
    end

    test "fails with invalid token" do
      assert {:error, :invalid_token} = Accounts.confirm_email("totally-invalid-token")
    end

    test "fails with already used token", %{user: user} do
      token = Accounts.generate_email_token(user, "confirm_email")
      assert {:ok, _} = Accounts.confirm_email(token)
      # Second use should fail
      assert {:error, :invalid_token} = Accounts.confirm_email(token)
    end
  end

  # ── request_password_reset/1 ────────────────────────────────

  describe "request_password_reset/1" do
    setup [:create_user]

    test "returns token for existing user", %{user: user} do
      assert {:ok, token} = Accounts.request_password_reset(user.email)
      assert is_binary(token)
    end

    test "returns nil for non-existent email" do
      assert {:ok, nil} = Accounts.request_password_reset("nobody@example.com")
    end
  end

  # ── reset_password/2 ────────────────────────────────────────

  describe "reset_password/2" do
    setup [:create_user]

    test "resets password with valid token", %{user: user} do
      {:ok, token} = Accounts.request_password_reset(user.email)
      assert {:ok, updated} = Accounts.reset_password(token, %{"password" => "ResetPwd789!"})
      assert updated.password_hash != user.password_hash
    end

    test "fails with invalid token" do
      assert {:error, :invalid_token} =
               Accounts.reset_password("bad-token", %{"password" => "ResetPwd789!"})
    end
  end

  # ── delete_user/1 ───────────────────────────────────────────

  describe "delete_user/1" do
    setup [:create_user]

    test "deletes the user", %{user: user} do
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert Accounts.get_user(user.id) == nil
    end
  end
end
