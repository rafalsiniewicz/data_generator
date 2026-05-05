defmodule DataGeneratorWeb.LoginLiveTest do
  use DataGeneratorWeb.ConnCase, async: true

  alias DataGenerator.Accounts

  # ── Helpers ───────────────────────────────────────────────────

  defp create_user(_context) do
    password = "Password123!"

    {:ok, user} =
      Accounts.register_user(%{
        "email" => "login_test@example.com",
        "login" => "login_tester",
        "password" => password
      })

    confirm_user_email(user)

    %{user: user, password: password}
  end

  # ── Rendering ───────────────────────────────────────────────

  describe "rendering" do
    test "renders login form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/login")

      assert has_element?(view, "#login-form")
      assert has_element?(view, "h1", "Welcome back")
    end

    test "has Sign up link", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/login")

      assert has_element?(view, "a", "Sign up")
    end

    test "has Forgot password? link", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/login")

      assert has_element?(view, "a", "Forgot password?")
    end
  end

  # ── Login flow ──────────────────────────────────────────────

  describe "login" do
    setup [:create_user]

    test "valid credentials redirect to dashboard", %{conn: conn, user: user, password: password} do
      # The login form POSTs to /login (controller action), not a LiveView event.
      # We test via the controller route directly.
      conn =
        post(conn, ~p"/login", %{
          "user" => %{
            "email_or_login" => user.email,
            "password" => password
          }
        })

      assert redirected_to(conn) == "/dashboard"
    end

    test "valid credentials with login username", %{conn: conn, password: password} do
      conn =
        post(conn, ~p"/login", %{
          "user" => %{
            "email_or_login" => "login_tester",
            "password" => password
          }
        })

      assert redirected_to(conn) == "/dashboard"
    end

    test "invalid credentials redirect back to login with error", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/login", %{
          "user" => %{
            "email_or_login" => user.email,
            "password" => "wrong_password"
          }
        })

      assert redirected_to(conn) == "/login"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Invalid"
    end
  end

  # ── Authenticated redirect ──────────────────────────────────

  describe "authenticated user" do
    setup :register_and_log_in_user

    test "redirects to dashboard when already logged in", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/dashboard"}}} = live(conn, ~p"/login")
    end
  end
end
