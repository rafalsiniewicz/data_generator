defmodule DataGeneratorWeb.DashboardLiveTest do
  use DataGeneratorWeb.ConnCase, async: true

  alias DataGenerator.Projects
  alias DataGenerator.Templates
  alias DataGenerator.Enums

  # ── Helpers ───────────────────────────────────────────────────

  defp create_user(_context) do
    user = insert(:user)
    %{user: user}
  end

  defp authenticate(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end

  # ── Authentication ───────────────────────────────────────────

  describe "authentication" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/dashboard")
    end
  end

  # ── Dashboard Content ────────────────────────────────────────

  describe "dashboard" do
    setup [:create_user, :authenticate]

    test "renders dashboard with greeting", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/dashboard")

      assert has_element?(view, "h1", "Dashboard")
      assert has_element?(view, "p", user.login)
    end

    test "shows zero counts initially", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/dashboard")

      assert has_element?(view, "p", "0")
    end

    test "shows correct template count", %{conn: conn, user: user} do
      insert(:template, user: user, name: "Template 1")
      insert(:template, user: user, name: "Template 2")

      {:ok, view, html} = live(conn, ~p"/dashboard")

      # The templates stat card should show 2
      assert html =~ "Templates"
      assert has_element?(view, "p", "2")
    end

    test "shows correct project count", %{conn: conn, user: user} do
      {:ok, _} = Projects.create_project(user.id, %{"name" => "P1"})
      {:ok, _} = Projects.create_project(user.id, %{"name" => "P2"})

      {:ok, view, _html} = live(conn, ~p"/dashboard")

      assert has_element?(view, "p", "2")
    end

    test "shows correct enum count", %{conn: conn, user: user} do
      insert(:enum_definition, user: user) |> with_values(["a"])
      insert(:enum_definition, user: user) |> with_values(["b"])
      insert(:enum_definition, user: user) |> with_values(["c"])

      {:ok, view, _html} = live(conn, ~p"/dashboard")

      assert has_element?(view, "p", "3")
    end

    test "shows recent projects", %{conn: conn, user: user} do
      {:ok, _} = Projects.create_project(user.id, %{"name" => "Recent Project"})

      {:ok, view, _html} = live(conn, ~p"/dashboard")

      assert has_element?(view, "p", "Recent Project")
    end

    test "shows empty state when no projects", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/dashboard")

      assert has_element?(view, "#recent-projects")
    end

    test "quick action links are present", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/dashboard")

      assert has_element?(view, "span", "New Template")
      assert has_element?(view, "span", "New Project")
      assert has_element?(view, "span", "New Enum")
    end

    test "no Generate Data or Quick Generate on dashboard", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/dashboard")

      refute has_element?(view, "span", "Generate Data")
      refute has_element?(view, "a", "Quick Generate")
    end
  end
end
