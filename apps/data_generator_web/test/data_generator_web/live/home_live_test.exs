defmodule DataGeneratorWeb.HomeLiveTest do
  use DataGeneratorWeb.ConnCase, async: true

  # ── Unauthenticated ─────────────────────────────────────────

  describe "unauthenticated" do
    test "renders landing page with Data Generator branding", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      assert html =~ "Data Generator"
      assert has_element?(view, "h1", "Data Generator")
    end

    test "shows Get Started for Free link to /register", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "a", "Get Started for Free")
    end

    test "shows Generate Ad-Hoc Data link to /generate", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "a", "Generate Ad-Hoc Data")
    end

    test "shows feature cards", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "h3", "25+ Data Types")
      assert has_element?(view, "h3", "Blazing Fast")
      assert has_element?(view, "h3", "Multiple Formats")
    end
  end

  # ── Authenticated ───────────────────────────────────────────

  describe "authenticated" do
    setup :register_and_log_in_user

    test "redirects to /dashboard", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/dashboard"}}} = live(conn, ~p"/")
    end
  end
end
