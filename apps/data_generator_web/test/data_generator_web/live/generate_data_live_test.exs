defmodule DataGeneratorWeb.GenerateDataLiveTest do
  use DataGeneratorWeb.ConnCase, async: true

  # ── Helpers ───────────────────────────────────────────────────

  defp create_and_auth_user(%{conn: conn}) do
    user = insert(:user)
    conn = log_in_user(conn, user)
    %{conn: conn, user: user}
  end

  # ── Unauthenticated ─────────────────────────────────────────

  describe "unauthenticated" do
    test "renders generation form without auth", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      assert has_element?(view, "h1", "Generate Data")
      # Should show sign up prompt for export
      assert has_element?(view, "a", "Sign up")
    end

    test "shows max 100 rows for guests", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/generate")

      assert html =~ "100"
    end
  end

  # ── Authenticated ───────────────────────────────────────────

  describe "authenticated" do
    setup [:create_and_auth_user]

    test "renders generation form for authenticated user", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      assert has_element?(view, "h1", "Generate Data")
    end

    test "shows max 1M rows for authenticated users", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/generate")

      assert html =~ "1000000"
    end
  end

  # ── Column management ──────────────────────────────────────

  describe "column management" do
    test "add column creates a new row", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      # Initially there's one column (column-0)
      assert has_element?(view, "#column-0")

      # Add a column
      render_click(view, "add_column")

      assert has_element?(view, "#column-1")
    end

    test "remove column removes a row", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      # Add a second column first
      render_click(view, "add_column")
      assert has_element?(view, "#column-0")
      assert has_element?(view, "#column-1")

      # Remove the second column
      render_click(view, "remove_column", %{"id" => "1"})

      refute has_element?(view, "#column-1")
      assert has_element?(view, "#column-0")
    end

    test "cannot remove the last column", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      # Only one column exists — remove button should be disabled
      assert has_element?(view, "#column-0")
      # The button with disabled attribute should be present
      assert has_element?(view, "button[disabled]")
    end
  end

  # ── Type selection ─────────────────────────────────────────

  describe "type selection" do
    test "selecting a type updates the column config area", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      # Select "integer" type for column 0
      render_click(view, "update_column_type", %{"id" => "0", "type_name" => "integer"})

      # Integer type shows min/max config
      html = render(view)
      assert html =~ "Range"
    end

    test "selecting enum type shows values input", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      render_click(view, "update_column_type", %{"id" => "0", "type_name" => "enum"})

      html = render(view)
      assert html =~ "comma-separated"
    end

    test "selecting regex type shows pattern input", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      render_click(view, "update_column_type", %{"id" => "0", "type_name" => "regex"})

      html = render(view)
      assert html =~ "Pattern"
    end
  end

  # ── Row count ──────────────────────────────────────────────

  describe "row count" do
    test "updates row count", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      render_click(view, "update_row_count", %{"value" => "50"})

      html = render(view)
      assert html =~ "50"
    end
  end

  # ── Generation ─────────────────────────────────────────────

  describe "generate" do
    test "shows error when no type selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      # Column 0 has no type selected by default
      render_click(view, "generate")

      assert has_element?(view, "#flash-error", "All columns must have a data type selected")
    end

    test "generates data and shows preview table", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      # Select a type for column 0
      render_click(view, "update_column_type", %{"id" => "0", "type_name" => "first_name"})
      render_click(view, "update_row_count", %{"value" => "5"})
      render_click(view, "generate")

      # Preview should appear
      assert has_element?(view, "#data-results")
      assert has_element?(view, "h2", "Preview")
    end
  end

  # ── Export (auth only) ──────────────────────────────────────

  describe "export" do
    setup [:create_and_auth_user]

    test "export buttons visible for authenticated users after generation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      # Generate some data first
      render_click(view, "update_column_type", %{"id" => "0", "type_name" => "boolean"})
      render_click(view, "update_row_count", %{"value" => "3"})
      render_click(view, "generate")

      # Export buttons should be present
      assert has_element?(view, "button", "CSV")
      assert has_element?(view, "button", "JSON")
      assert has_element?(view, "button", "SQL")
    end

    test "export buttons not visible for unauthenticated users" do
      # Build a fresh unauthenticated conn
      conn = Phoenix.ConnTest.build_conn()

      {:ok, view, _html} = live(conn, ~p"/generate")

      render_click(view, "update_column_type", %{"id" => "0", "type_name" => "boolean"})
      render_click(view, "update_row_count", %{"value" => "3"})
      render_click(view, "generate")

      # Should show "Sign up to export" instead of buttons
      assert has_element?(view, "a", "Sign up")
      refute has_element?(view, "button", "CSV")
    end

    test "export CSV triggers download event", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      render_click(view, "update_column_type", %{"id" => "0", "type_name" => "boolean"})
      render_click(view, "update_row_count", %{"value" => "2"})
      render_click(view, "generate")

      # Export should push a download event (handled by JS hook)
      render_click(view, "export", %{"format" => "csv"})

      # The push_event happens internally; we verify no error flash
      refute has_element?(view, "#flash-error")
    end

    test "export JSON triggers download event", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      render_click(view, "update_column_type", %{"id" => "0", "type_name" => "integer"})
      render_click(view, "update_row_count", %{"value" => "2"})
      render_click(view, "generate")

      render_click(view, "export", %{"format" => "json"})
      refute has_element?(view, "#flash-error")
    end

    test "export SQL triggers download event", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/generate")

      render_click(view, "update_column_type", %{"id" => "0", "type_name" => "uuid"})
      render_click(view, "update_row_count", %{"value" => "2"})
      render_click(view, "generate")

      render_click(view, "export", %{"format" => "sql"})
      refute has_element?(view, "#flash-error")
    end
  end
end
