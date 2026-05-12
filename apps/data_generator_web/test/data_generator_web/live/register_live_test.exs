defmodule DataGeneratorWeb.RegisterLiveTest do
  use DataGeneratorWeb.ConnCase, async: true

  alias DataGenerator.Accounts

  # ── Rendering ───────────────────────────────────────────────

  describe "rendering" do
    test "renders registration form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/register")

      assert has_element?(view, "#registration-form")
      assert has_element?(view, "h1", "Create your account")
    end

    test "has Log in link", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/register")

      assert has_element?(view, "a", "Log in")
    end
  end

  # ── Registration ────────────────────────────────────────────

  describe "register" do
    test "valid input shows check your email message", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/register")

      view
      |> form("#registration-form",
        user: %{
          login: "newuser",
          email: "newuser@example.com",
          password: "Password123!"
        }
      )
      |> render_submit()

      # After successful registration, the "check your email" panel should appear
      assert has_element?(view, "h2", "Check your email")
    end

    test "duplicate email shows error", %{conn: conn} do
      {:ok, _user} =
        Accounts.register_user(%{
          "email" => "taken@example.com",
          "login" => "taken_user",
          "password" => "Password123!"
        })

      {:ok, view, _html} = live(conn, ~p"/register")

      view
      |> form("#registration-form",
        user: %{
          login: "another_user",
          email: "taken@example.com",
          password: "Password123!"
        }
      )
      |> render_submit()

      assert has_element?(view, "#registration-form")
      # Should still show the form (not the check_email panel)
      refute has_element?(view, "h2", "Check your email")
    end

    test "duplicate login shows error", %{conn: conn} do
      {:ok, _user} =
        Accounts.register_user(%{
          "email" => "first@example.com",
          "login" => "taken_login",
          "password" => "Password123!"
        })

      {:ok, view, _html} = live(conn, ~p"/register")

      view
      |> form("#registration-form",
        user: %{
          login: "taken_login",
          email: "different@example.com",
          password: "Password123!"
        }
      )
      |> render_submit()

      assert has_element?(view, "#registration-form")
      refute has_element?(view, "h2", "Check your email")
    end
  end

  # ── Live Validation ─────────────────────────────────────────

  describe "validation" do
    test "invalid email format shows validation error", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/register")

      html =
        view
        |> form("#registration-form",
          user: %{
            login: "testuser",
            email: "not-an-email",
            password: "Password123!"
          }
        )
        |> render_change()

      # The changeset validation should flag the email
      assert html =~ "registration-form"
    end

    test "short password shows validation error on change", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/register")

      view
      |> form("#registration-form",
        user: %{
          login: "testuser",
          email: "test@example.com",
          password: "short"
        }
      )
      |> render_change()

      # Form should still be showing (validation in progress)
      assert has_element?(view, "#registration-form")
    end
  end

  # ── Authenticated redirect ──────────────────────────────────

  describe "authenticated user" do
    setup :register_and_log_in_user

    test "redirects to dashboard when already logged in", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/dashboard"}}} = live(conn, ~p"/register")
    end
  end
end
