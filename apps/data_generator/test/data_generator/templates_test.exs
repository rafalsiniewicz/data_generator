defmodule DataGenerator.TemplatesTest do
  use DataGenerator.DataCase, async: true

  alias DataGenerator.Templates
  alias DataGenerator.Templates.Template
  alias DataGenerator.Templates.Column

  # ── Helpers ───────────────────────────────────────────────────

  defp create_user(_context) do
    user = insert(:user)
    %{user: user}
  end

  defp create_type(_context) do
    type = insert(:type, name: "first_name")
    %{type: type}
  end

  defp create_template(%{user: user, type: type}) do
    template =
      insert(:template, user: user)
      |> with_columns([{"first_name", type}, {"age", type, %{"min" => 1, "max" => 100}}])

    %{template: template}
  end

  # ── create_template/2 ────────────────────────────────────────

  describe "create_template/2" do
    setup [:create_user, :create_type]

    test "valid attrs with columns succeeds", %{user: user, type: type} do
      attrs = %{
        "name" => "User Data",
        "number_of_rows" => 500,
        "description" => "Generate user data",
        "columns" => [
          %{"name" => "first_name", "type_id" => type.id, "config" => %{}},
          %{"name" => "age", "type_id" => type.id, "config" => %{"min" => 1, "max" => 100}}
        ]
      }

      assert {:ok, %Template{} = template} = Templates.create_template(user.id, attrs)
      assert template.name == "User Data"
      assert template.number_of_rows == 500
      assert template.description == "Generate user data"
      assert template.user_id == user.id
      assert length(template.columns) == 2

      col_names = Enum.map(template.columns, & &1.name) |> Enum.sort()
      assert col_names == ["age", "first_name"]
    end

    test "valid attrs without columns succeeds", %{user: user} do
      attrs = %{
        "name" => "Empty Template",
        "number_of_rows" => 10
      }

      assert {:ok, %Template{} = template} = Templates.create_template(user.id, attrs)
      assert template.name == "Empty Template"
    end

    test "missing name fails", %{user: user} do
      attrs = %{"number_of_rows" => 100}

      assert {:error, changeset} = Templates.create_template(user.id, attrs)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "missing number_of_rows fails", %{user: user} do
      attrs = %{"name" => "Test"}

      assert {:error, changeset} = Templates.create_template(user.id, attrs)
      assert "can't be blank" in errors_on(changeset).number_of_rows
    end

    test "number_of_rows <= 0 fails", %{user: user} do
      attrs = %{"name" => "Test", "number_of_rows" => 0}

      assert {:error, changeset} = Templates.create_template(user.id, attrs)
      assert errors_on(changeset).number_of_rows != []

      attrs2 = %{"name" => "Test", "number_of_rows" => -5}

      assert {:error, changeset2} = Templates.create_template(user.id, attrs2)
      assert errors_on(changeset2).number_of_rows != []
    end

    test "duplicate (user_id, name) fails", %{user: user} do
      attrs = %{"name" => "Duplicated", "number_of_rows" => 100}

      assert {:ok, _} = Templates.create_template(user.id, attrs)
      assert {:error, changeset} = Templates.create_template(user.id, attrs)
      assert "has already been taken" in errors_on(changeset).name
    end

    test "different users can have same template name", %{user: user} do
      other_user = insert(:user)
      attrs = %{"name" => "Shared Name", "number_of_rows" => 50}

      assert {:ok, _} = Templates.create_template(user.id, attrs)
      assert {:ok, _} = Templates.create_template(other_user.id, attrs)
    end

    test "name too long fails", %{user: user} do
      attrs = %{
        "name" => String.duplicate("a", 256),
        "number_of_rows" => 10
      }

      assert {:error, changeset} = Templates.create_template(user.id, attrs)
      assert errors_on(changeset).name != []
    end
  end

  # ── update_template/2 ────────────────────────────────────────

  describe "update_template/2" do
    setup [:create_user, :create_type, :create_template]

    test "can change name", %{template: template} do
      assert {:ok, updated} = Templates.update_template(template, %{"name" => "Renamed"})
      assert updated.name == "Renamed"
    end

    test "can change number_of_rows", %{template: template} do
      assert {:ok, updated} = Templates.update_template(template, %{"number_of_rows" => 999})
      assert updated.number_of_rows == 999
    end

    test "can change description", %{template: template} do
      assert {:ok, updated} = Templates.update_template(template, %{"description" => "New desc"})
      assert updated.description == "New desc"
    end

    test "can add columns", %{template: template, type: type} do
      existing =
        Enum.map(template.columns, fn col ->
          %{"id" => col.id, "name" => col.name, "type_id" => col.type_id, "config" => col.config}
        end)

      new_columns = existing ++ [%{"name" => "email", "type_id" => type.id, "config" => %{}}]
      attrs = %{"columns" => new_columns}

      assert {:ok, updated} = Templates.update_template(template, attrs)
      updated = Repo.preload(updated, :columns, force: true)
      assert length(updated.columns) == 3
    end

    test "can remove columns (on_replace: :delete)", %{template: template} do
      first = hd(template.columns)

      attrs = %{
        "columns" => [
          %{
            "id" => first.id,
            "name" => first.name,
            "type_id" => first.type_id,
            "config" => first.config
          }
        ]
      }

      assert {:ok, updated} = Templates.update_template(template, attrs)
      updated = Repo.preload(updated, :columns, force: true)
      assert length(updated.columns) == 1
      assert hd(updated.columns).name == first.name
    end

    test "uniqueness still enforced on name", %{user: user, template: template} do
      insert(:template, user: user, name: "Taken")

      assert {:error, changeset} = Templates.update_template(template, %{"name" => "Taken"})
      assert "has already been taken" in errors_on(changeset).name
    end
  end

  # ── delete_template/1 ────────────────────────────────────────

  describe "delete_template/1" do
    setup [:create_user, :create_type, :create_template]

    test "deletes the template and cascades to columns", %{template: template} do
      column_ids = Enum.map(template.columns, & &1.id)
      assert {:ok, _} = Templates.delete_template(template)

      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Template, template.id) end

      for id <- column_ids do
        assert Repo.get(Column, id) == nil
      end
    end
  end

  # ── list_user_templates/2 ────────────────────────────────────

  describe "list_user_templates/2" do
    setup [:create_user, :create_type]

    test "returns only templates owned by user", %{user: user} do
      other_user = insert(:user)

      insert(:template, user: user, name: "Mine")
      insert(:template, user: other_user, name: "NotMine")

      templates = Templates.list_user_templates(user.id)
      assert length(templates) == 1
      assert hd(templates).name == "Mine"
    end

    test "preloads columns with types", %{user: user, type: type} do
      insert(:template, user: user)
      |> with_columns([{"col1", type}])

      [template] = Templates.list_user_templates(user.id)
      assert length(template.columns) == 1
      col = hd(template.columns)
      assert col.name == "col1"
      assert col.type != nil
    end

    test "orders by inserted_at descending", %{user: user} do
      t1 = insert(:template, user: user, name: "First")
      # Ensure different timestamps
      t2 = insert(:template, user: user, name: "Second")

      templates = Templates.list_user_templates(user.id)
      names = Enum.map(templates, & &1.name)
      # Second inserted last, should appear first
      assert hd(names) == "Second"
    end

    test "search filters by name (case-insensitive)", %{user: user} do
      insert(:template, user: user, name: "User Data")
      insert(:template, user: user, name: "Product List")

      assert [t] = Templates.list_user_templates(user.id, search: "user")
      assert t.name == "User Data"

      assert [t] = Templates.list_user_templates(user.id, search: "PRODUCT")
      assert t.name == "Product List"
    end

    test "search with no match returns empty list", %{user: user} do
      insert(:template, user: user, name: "Data")

      assert [] = Templates.list_user_templates(user.id, search: "nonexistent")
    end

    test "empty search returns all", %{user: user} do
      insert(:template, user: user, name: "A")
      insert(:template, user: user, name: "B")

      assert length(Templates.list_user_templates(user.id, search: "")) == 2
      assert length(Templates.list_user_templates(user.id, search: nil)) == 2
    end
  end

  # ── get_user_template!/2 ─────────────────────────────────────

  describe "get_user_template!/2" do
    setup [:create_user, :create_type, :create_template]

    test "returns the template for the correct user", %{user: user, template: template} do
      result = Templates.get_user_template!(user.id, template.id)
      assert result.id == template.id
      assert result.user_id == user.id
    end

    test "preloads columns with types", %{user: user, template: template} do
      result = Templates.get_user_template!(user.id, template.id)
      assert length(result.columns) == 2
      assert Enum.all?(result.columns, &(&1.type != nil))
    end

    test "raises if template belongs to another user", %{template: template} do
      other_user = insert(:user)

      assert_raise Ecto.NoResultsError, fn ->
        Templates.get_user_template!(other_user.id, template.id)
      end
    end

    test "raises if template does not exist", %{user: user} do
      assert_raise Ecto.NoResultsError, fn ->
        Templates.get_user_template!(user.id, -1)
      end
    end
  end

  # ── get_template_with_columns!/1 ─────────────────────────────

  describe "get_template_with_columns!/1" do
    setup [:create_user, :create_type, :create_template]

    test "returns template with preloaded columns and types", %{template: template} do
      result = Templates.get_template_with_columns!(template.id)
      assert result.id == template.id
      assert length(result.columns) == 2
    end

    test "raises if not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Templates.get_template_with_columns!(-1)
      end
    end
  end

  # ── change_template/2 ────────────────────────────────────────

  describe "change_template/2" do
    setup [:create_user, :create_type, :create_template]

    test "returns a changeset", %{template: template} do
      changeset = Templates.change_template(template)
      assert %Ecto.Changeset{} = changeset
    end

    test "changeset with valid attrs is valid", %{template: template} do
      changeset = Templates.change_template(template, %{"name" => "NewName"})
      assert changeset.valid?
    end
  end
end
