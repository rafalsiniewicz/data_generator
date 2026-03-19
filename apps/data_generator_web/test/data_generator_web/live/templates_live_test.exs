defmodule DataGeneratorWeb.TemplatesLiveTest do
  use DataGeneratorWeb.ConnCase, async: true

  alias DataGenerator.Templates

  # ── Helpers ───────────────────────────────────────────────────

  defp create_user(_context) do
    user = insert(:user)
    %{user: user}
  end

  defp create_type(_context) do
    type = insert(:type, name: "first_name_#{System.unique_integer([:positive])}")
    %{type: type}
  end

  defp create_template(%{user: user, type: type}) do
    template =
      insert(:template, user: user, name: "User Data")
      |> with_columns([{"first_name", type}, {"age", type}])

    %{template: template}
  end

  defp authenticate(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end

  # ── Authentication Required ──────────────────────────────────

  describe "authentication" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/templates")
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/templates/new")
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/templates/1/edit")
    end
  end

  # ── Index ────────────────────────────────────────────────────

  describe "Index" do
    setup [:create_user, :create_type, :authenticate, :create_template]

    test "lists user's templates", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/templates")

      assert has_element?(view, "h1", "Templates")
      assert has_element?(view, "h3", "User Data")
    end

    test "shows column count and row count", %{conn: conn, template: template} do
      {:ok, view, _html} = live(conn, ~p"/templates")

      assert has_element?(view, "p", "#{length(template.columns)} columns")
      assert has_element?(view, "p", "#{template.number_of_rows} rows")
    end

    test "does not show other user's templates", %{conn: conn, type: type} do
      other_user = insert(:user)

      insert(:template, user: other_user, name: "OtherTemplate")
      |> with_columns([{"col", type}])

      {:ok, view, _html} = live(conn, ~p"/templates")

      refute has_element?(view, "h3", "OtherTemplate")
    end

    test "search filters results", %{conn: conn, user: user, type: type} do
      insert(:template, user: user, name: "Product List")
      |> with_columns([{"product", type}])

      {:ok, view, _html} = live(conn, ~p"/templates")

      # Both templates visible initially
      assert has_element?(view, "h3", "User Data")
      assert has_element?(view, "h3", "Product List")

      # Search for "user" — only User Data should appear
      view |> element("#template-search") |> render_change(%{"search" => "user"})

      assert has_element?(view, "h3", "User Data")
      refute has_element?(view, "h3", "Product List")
    end

    test "empty search shows all templates", %{conn: conn, user: user, type: type} do
      insert(:template, user: user, name: "Product List")
      |> with_columns([{"product", type}])

      {:ok, view, _html} = live(conn, ~p"/templates")

      # Filter then clear
      view |> element("#template-search") |> render_change(%{"search" => "user"})
      view |> element("#template-search") |> render_change(%{"search" => ""})

      assert has_element?(view, "h3", "User Data")
      assert has_element?(view, "h3", "Product List")
    end

    test "shows empty state when no templates exist", %{conn: conn, user: user} do
      # Delete all templates for this user
      for template <- Templates.list_user_templates(user.id) do
        Templates.delete_template(template)
      end

      {:ok, view, _html} = live(conn, ~p"/templates")

      assert has_element?(view, "h3", "No templates yet")
    end

    test "delete removes template from list", %{conn: conn, template: template} do
      {:ok, view, _html} = live(conn, ~p"/templates")

      assert has_element?(view, "h3", "User Data")

      view
      |> element("button[phx-click=delete][phx-value-id=#{template.id}]")
      |> render_click()

      refute has_element?(view, "h3", "User Data")
    end

    test "New Template link navigates to /templates/new", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/templates")

      assert has_element?(view, "a[href=\"/templates/new\"]")
    end
  end

  # ── New ──────────────────────────────────────────────────────

  describe "New" do
    setup [:create_user, :create_type, :authenticate]

    test "renders new template form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/templates/new")

      assert has_element?(view, "h1", "New Template")
      assert has_element?(view, "#template-form")
    end

    test "validation shows errors for empty name", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/templates/new")

      view
      |> form("#template-form", %{
        "template" => %{"name" => "", "number_of_rows" => "100"}
      })
      |> render_change()

      assert has_element?(view, "[phx-feedback-for]", "can't be blank")
    end

    test "add column button adds new column row", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/templates/new")

      assert has_element?(view, "#new-col-0")
      refute has_element?(view, "#new-col-1")

      view |> element("button", "Add Column") |> render_click()

      assert has_element?(view, "#new-col-1")
    end

    test "remove column button removes column row", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/templates/new")

      # Add a second column first
      view |> element("button", "Add Column") |> render_click()
      assert has_element?(view, "#new-col-1")

      # Remove the second column
      view
      |> element("button[phx-click=remove_column][phx-value-id=\"1\"]")
      |> render_click()

      refute has_element?(view, "#new-col-1")
    end

    test "cannot remove last column", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/templates/new")

      # The remove button for the only column should be disabled
      assert has_element?(view, "button[phx-click=remove_column][disabled]")
    end

    test "back link navigates to /templates", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/templates/new")

      assert has_element?(view, "a[href=\"/templates\"]", "Back to Templates")
    end
  end

  # ── Edit ─────────────────────────────────────────────────────

  describe "Edit" do
    setup [:create_user, :create_type, :authenticate, :create_template]

    test "renders edit form with existing data", %{conn: conn, template: template} do
      {:ok, view, _html} = live(conn, ~p"/templates/#{template.id}/edit")

      assert has_element?(view, "h1", "Edit Template")
      assert has_element?(view, "#template-edit-form")
    end

    test "add column button works", %{conn: conn, template: template} do
      {:ok, view, _html} = live(conn, ~p"/templates/#{template.id}/edit")

      # Existing columns occupy edit-col-0 and edit-col-1
      next_id = length(template.columns)

      view |> element("button", "Add Column") |> render_click()

      assert has_element?(view, "#edit-col-#{next_id}")
    end

    test "remove column button works", %{conn: conn, template: template} do
      {:ok, view, _html} = live(conn, ~p"/templates/#{template.id}/edit")

      # Remove the second column (edit-col-1)
      view
      |> element("button[phx-click=remove_column][phx-value-id=\"1\"]")
      |> render_click()

      refute has_element?(view, "#edit-col-1")
    end

    test "cannot access another user's template", %{conn: conn, type: type} do
      other_user = insert(:user)

      other_template =
        insert(:template, user: other_user, name: "Secret")
        |> with_columns([{"col", type}])

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/templates/#{other_template.id}/edit")
      end
    end

    test "back link navigates to /templates", %{conn: conn, template: template} do
      {:ok, view, _html} = live(conn, ~p"/templates/#{template.id}/edit")

      assert has_element?(view, "a[href=\"/templates\"]", "Back to Templates")
    end

    test "validation shows errors on empty name", %{conn: conn, template: template} do
      {:ok, view, _html} = live(conn, ~p"/templates/#{template.id}/edit")

      view
      |> form("#template-edit-form", %{
        "template" => %{"name" => "", "number_of_rows" => "100"}
      })
      |> render_change()

      assert has_element?(view, "[phx-feedback-for]", "can't be blank")
    end
  end
end
