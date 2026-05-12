defmodule DataGeneratorWeb.EnumsLiveTest do
  use DataGeneratorWeb.ConnCase, async: true

  alias DataGenerator.Enums

  # ── Helpers ───────────────────────────────────────────────────

  defp create_user(_context) do
    user = insert(:user)
    %{user: user}
  end

  defp create_enum(%{user: user}) do
    enum =
      insert(:enum_definition, user: user, name: "Colors")
      |> with_values(["red", "green", "blue"])

    %{enum: enum}
  end

  defp authenticate(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end

  # ── Authentication Required ──────────────────────────────────

  describe "authentication" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/enums")
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/enums/new")
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/enums/1/edit")
    end
  end

  # ── Index ────────────────────────────────────────────────────

  describe "Index" do
    setup [:create_user, :authenticate, :create_enum]

    test "lists user's enums", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/enums")

      assert has_element?(view, "h1", "Custom Enums")
      assert has_element?(view, "h3", "Colors")
    end

    test "shows value count", %{conn: conn, enum: enum} do
      {:ok, view, _html} = live(conn, ~p"/enums")

      assert has_element?(view, "p", "#{length(enum.enum_values)} values")
    end

    test "shows value preview badges", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/enums")

      assert has_element?(view, "span", "red")
      assert has_element?(view, "span", "green")
      assert has_element?(view, "span", "blue")
    end

    test "does not show other user's enums", %{conn: conn} do
      other_user = insert(:user)
      insert(:enum_definition, user: other_user, name: "OtherEnum") |> with_values(["x"])

      {:ok, view, _html} = live(conn, ~p"/enums")

      refute has_element?(view, "h3", "OtherEnum")
    end

    test "search filters results", %{conn: conn, user: user} do
      insert(:enum_definition, user: user, name: "Statuses") |> with_values(["active"])

      {:ok, view, _html} = live(conn, ~p"/enums")

      # Both enums visible initially
      assert has_element?(view, "h3", "Colors")
      assert has_element?(view, "h3", "Statuses")

      # Search for "color" — only Colors should appear
      view |> element("#enum-search") |> render_change(%{"search" => "color"})

      assert has_element?(view, "h3", "Colors")
      refute has_element?(view, "h3", "Statuses")
    end

    test "empty search shows all enums", %{conn: conn, user: user} do
      insert(:enum_definition, user: user, name: "Statuses") |> with_values(["active"])

      {:ok, view, _html} = live(conn, ~p"/enums")

      # Filter then clear
      view |> element("#enum-search") |> render_change(%{"search" => "color"})
      view |> element("#enum-search") |> render_change(%{"search" => ""})

      assert has_element?(view, "h3", "Colors")
      assert has_element?(view, "h3", "Statuses")
    end

    test "shows empty state when no enums exist", %{conn: conn, user: user} do
      # Delete all enums for this user
      for enum <- Enums.list_user_enums(user.id) do
        Enums.delete_enum(enum)
      end

      {:ok, view, _html} = live(conn, ~p"/enums")

      assert has_element?(view, "h3", "No custom enums yet")
    end

    test "delete removes enum from list", %{conn: conn, enum: enum} do
      {:ok, view, _html} = live(conn, ~p"/enums")

      assert has_element?(view, "h3", "Colors")

      view
      |> element("button[phx-click=delete][phx-value-id=#{enum.id}]")
      |> render_click()

      refute has_element?(view, "h3", "Colors")
    end

    test "New Enum link navigates to /enums/new", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/enums")

      assert has_element?(view, "a[href=\"/enums/new\"]")
    end
  end

  # ── New ──────────────────────────────────────────────────────

  describe "New" do
    setup [:create_user, :authenticate]

    test "renders new enum form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/enums/new")

      assert has_element?(view, "h1", "New Enum")
      assert has_element?(view, "#enum-form")
    end

    test "creating enum with valid data succeeds", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/enums/new")

      view
      |> form("#enum-form", %{
        "enum" => %{"name" => "Sizes"},
        "values" => %{"val-0" => "small"}
      })
      |> render_submit()

      assert_redirected(view, ~p"/enums")
    end

    test "validation shows errors for empty name", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/enums/new")

      view
      |> form("#enum-form", %{
        "enum" => %{"name" => ""},
        "values" => %{"val-0" => "something"}
      })
      |> render_change()

      assert has_element?(view, "[phx-feedback-for]", "can't be blank")
    end

    test "add value button adds new value input", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/enums/new")

      assert has_element?(view, "#value-val-0")
      refute has_element?(view, "#value-val-1")

      view |> element("button", "Add Value") |> render_click()

      assert has_element?(view, "#value-val-1")
    end

    test "remove value button removes value input", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/enums/new")

      # Add a second value first
      view |> element("button", "Add Value") |> render_click()
      assert has_element?(view, "#value-val-1")

      # Remove the second value
      view
      |> element("button[phx-click=remove_value][phx-value-id=val-1]")
      |> render_click()

      refute has_element?(view, "#value-val-1")
    end

    test "cannot remove last value", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/enums/new")

      # The remove button for the only value should be disabled
      assert has_element?(view, "button[phx-click=remove_value][disabled]")
    end

    test "back link navigates to /enums", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/enums/new")

      assert has_element?(view, "a[href=\"/enums\"]", "Back to Enums")
    end
  end

  # ── Edit ─────────────────────────────────────────────────────

  describe "Edit" do
    setup [:create_user, :authenticate, :create_enum]

    test "renders edit form with existing data", %{conn: conn, enum: enum} do
      {:ok, view, _html} = live(conn, ~p"/enums/#{enum.id}/edit")

      assert has_element?(view, "h1", "Edit Enum")
      assert has_element?(view, "#enum-edit-form")

      # Existing values should be populated
      html = render(view)
      assert html =~ "red"
      assert html =~ "green"
      assert html =~ "blue"
    end

    test "can modify name and save", %{conn: conn, enum: enum} do
      {:ok, view, _html} = live(conn, ~p"/enums/#{enum.id}/edit")

      # Build the existing values params (keeping db IDs)
      values_params =
        enum.enum_values
        |> Enum.with_index()
        |> Enum.reduce(%{}, fn {ev, idx}, acc ->
          Map.put(acc, "val-#{idx}", ev.value)
        end)

      view
      |> form("#enum-edit-form", %{
        "enum" => %{"name" => "Updated Colors"},
        "values" => values_params
      })
      |> render_submit()

      assert_redirected(view, ~p"/enums")

      # Verify the rename happened in the DB
      updated = Enums.get_enum!(enum.id)
      assert updated.name == "Updated Colors"
    end

    test "add value button works", %{conn: conn, enum: enum} do
      {:ok, view, _html} = live(conn, ~p"/enums/#{enum.id}/edit")

      # Existing values occupy val-0 through val-2
      next_id = length(enum.enum_values)

      view |> element("button", "Add Value") |> render_click()

      assert has_element?(view, "#edit-value-val-#{next_id}")
    end

    test "remove value button works", %{conn: conn, enum: enum} do
      {:ok, view, _html} = live(conn, ~p"/enums/#{enum.id}/edit")

      # Remove the third value (val-2)
      view
      |> element("button[phx-click=remove_value][phx-value-id=val-2]")
      |> render_click()

      refute has_element?(view, "#edit-value-val-2")
    end

    test "cannot access another user's enum", %{conn: conn} do
      other_user = insert(:user)

      other_enum =
        insert(:enum_definition, user: other_user, name: "Secret")
        |> with_values(["hidden"])

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/enums/#{other_enum.id}/edit")
      end
    end

    test "back link navigates to /enums", %{conn: conn, enum: enum} do
      {:ok, view, _html} = live(conn, ~p"/enums/#{enum.id}/edit")

      assert has_element?(view, "a[href=\"/enums\"]", "Back to Enums")
    end

    test "validation shows errors on empty name", %{conn: conn, enum: enum} do
      {:ok, view, _html} = live(conn, ~p"/enums/#{enum.id}/edit")

      values_params =
        enum.enum_values
        |> Enum.with_index()
        |> Enum.reduce(%{}, fn {ev, idx}, acc ->
          Map.put(acc, "val-#{idx}", ev.value)
        end)

      view
      |> form("#enum-edit-form", %{
        "enum" => %{"name" => ""},
        "values" => values_params
      })
      |> render_change()

      assert has_element?(view, "[phx-feedback-for]", "can't be blank")
    end
  end
end
