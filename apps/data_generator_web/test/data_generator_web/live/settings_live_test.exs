defmodule DataGeneratorWeb.SettingsLiveTest do
  use DataGeneratorWeb.ConnCase, async: true

  alias DataGenerator.Accounts

  # ── Helpers ───────────────────────────────────────────────────

  defp create_and_auth_user(%{conn: conn}) do
    password = "Password123!"

    {:ok, user} =
      Accounts.register_user(%{
        "email" => "settings_test@example.com",
        "login" => "settings_tester",
        "password" => password
      })

    conn = log_in_user(conn, user)
    %{conn: conn, user: user, password: password}
  end

  # ── Authentication ──────────────────────────────────────────

  describe "authentication" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/settings")
    end
  end

  # ── Rendering ───────────────────────────────────────────────

  describe "rendering" do
    setup [:create_and_auth_user]

    test "shows settings page with account info", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      assert has_element?(view, "h1", "Settings")
      assert has_element?(view, "h2", "Account Information")
      assert has_element?(view, "dd", user.login)
      assert has_element?(view, "dd", user.email)
    end

    test "shows change password form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      assert has_element?(view, "#password-form")
      assert has_element?(view, "h2", "Change Password")
    end

    test "shows danger zone with delete button", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      assert has_element?(view, "h2", "Danger Zone")
      assert has_element?(view, "button", "Delete my account")
    end
  end

  # ── Change Password ─────────────────────────────────────────

  describe "change password" do
    setup [:create_and_auth_user]

    test "valid current + new password succeeds", %{conn: conn, password: password} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      view
      |> form("#password-form",
        password: %{
          current_password: password,
          password: "NewPassword456!"
        }
      )
      |> render_submit()

      assert has_element?(view, "#flash-info", "Password updated successfully")
    end

    test "wrong current password shows error", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      html =
        view
        |> form("#password-form",
          password: %{
            current_password: "wrong_password",
            password: "NewPassword456!"
          }
        )
        |> render_submit()

      # The form should re-render with error (no success flash)
      refute has_element?(view, "#flash-info", "Password updated successfully")
      # Form should still be visible
      assert has_element?(view, "#password-form")
    end
  end

  # ── Delete Account ──────────────────────────────────────────

  describe "delete account" do
    setup [:create_and_auth_user]

    test "deleting account redirects to home", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      html = render_click(view, "delete_account")

      # Should redirect to home page
      assert_redirect(view, "/")

      # User should be deleted from DB
      assert Accounts.get_user(user.id) == nil
    end
  end
end
