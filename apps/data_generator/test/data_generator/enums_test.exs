defmodule DataGenerator.EnumsTest do
  use DataGenerator.DataCase, async: true

  alias DataGenerator.Enums
  alias DataGenerator.Enums.Enum, as: UserEnum
  alias DataGenerator.Enums.EnumValue

  # ── Helpers ───────────────────────────────────────────────────

  defp create_user(_context) do
    user = insert(:user)
    %{user: user}
  end

  defp create_enum(%{user: user}) do
    enum = insert(:enum_definition, user: user) |> with_values(["red", "green", "blue"])
    %{enum: enum}
  end

  # ── create_enum/2 ─────────────────────────────────────────────

  describe "create_enum/2" do
    setup [:create_user]

    test "valid name + values succeeds", %{user: user} do
      attrs = %{
        "name" => "Colors",
        "enum_values" => [
          %{"value" => "red"},
          %{"value" => "green"},
          %{"value" => "blue"}
        ]
      }

      assert {:ok, %UserEnum{} = enum} = Enums.create_enum(user.id, attrs)
      assert enum.name == "Colors"
      assert enum.user_id == user.id
      assert length(enum.enum_values) == 3

      value_names = Enum.map(enum.enum_values, & &1.value) |> Enum.sort()
      assert value_names == ["blue", "green", "red"]
    end

    test "duplicate (user_id, name) fails", %{user: user} do
      attrs = %{
        "name" => "Statuses",
        "enum_values" => [%{"value" => "active"}]
      }

      assert {:ok, _} = Enums.create_enum(user.id, attrs)
      assert {:error, changeset} = Enums.create_enum(user.id, attrs)
      assert "has already been taken" in errors_on(changeset).name
    end

    test "different users can have same enum name", %{user: user} do
      other_user = insert(:user)

      attrs = %{
        "name" => "Shared Name",
        "enum_values" => [%{"value" => "val1"}]
      }

      assert {:ok, _} = Enums.create_enum(user.id, attrs)
      assert {:ok, _} = Enums.create_enum(other_user.id, attrs)
    end

    test "empty values list fails", %{user: user} do
      attrs = %{"name" => "Empty", "enum_values" => []}

      assert {:error, changeset} = Enums.create_enum(user.id, attrs)
      assert "must have at least one value" in errors_on(changeset).enum_values
    end

    test "missing name fails", %{user: user} do
      attrs = %{"enum_values" => [%{"value" => "something"}]}

      assert {:error, changeset} = Enums.create_enum(user.id, attrs)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "name too long fails", %{user: user} do
      attrs = %{
        "name" => String.duplicate("a", 101),
        "enum_values" => [%{"value" => "x"}]
      }

      assert {:error, changeset} = Enums.create_enum(user.id, attrs)
      assert errors_on(changeset).name != []
    end

    test "value too long fails", %{user: user} do
      attrs = %{
        "name" => "Test",
        "enum_values" => [%{"value" => String.duplicate("v", 51)}]
      }

      assert {:error, changeset} = Enums.create_enum(user.id, attrs)
      assert errors_on(changeset).enum_values != []
    end

    test "duplicate values within same enum fails at DB level", %{user: user} do
      attrs = %{
        "name" => "Dupes",
        "enum_values" => [%{"value" => "same"}, %{"value" => "same"}]
      }

      assert {:error, _changeset} = Enums.create_enum(user.id, attrs)
    end

    test "user_id cannot be overridden through attrs", %{user: user} do
      other_user = insert(:user)

      attrs = %{
        "name" => "Overridden",
        "user_id" => other_user.id,
        "enum_values" => [%{"value" => "x"}]
      }

      assert {:ok, enum} = Enums.create_enum(user.id, attrs)
      assert enum.user_id == user.id
    end
  end

  # ── update_enum/2 ─────────────────────────────────────────────

  describe "update_enum/2" do
    setup [:create_user, :create_enum]

    test "can rename", %{enum: enum} do
      assert {:ok, updated} = Enums.update_enum(enum, %{"name" => "Renamed"})
      assert updated.name == "Renamed"
    end

    test "can add values", %{enum: enum} do
      existing =
        Enum.map(enum.enum_values, fn ev -> %{"id" => ev.id, "value" => ev.value} end)

      new_values = existing ++ [%{"value" => "yellow"}]
      attrs = %{"enum_values" => new_values}

      assert {:ok, updated} = Enums.update_enum(enum, attrs)
      updated = Repo.preload(updated, :enum_values, force: true)
      assert length(updated.enum_values) == 4
    end

    test "can remove values (on_replace: :delete)", %{enum: enum} do
      # Keep only the first value
      first = hd(enum.enum_values)
      attrs = %{"enum_values" => [%{"id" => first.id, "value" => first.value}]}

      assert {:ok, updated} = Enums.update_enum(enum, attrs)
      updated = Repo.preload(updated, :enum_values, force: true)
      assert length(updated.enum_values) == 1
      assert hd(updated.enum_values).value == first.value
    end

    test "removing all values fails validation", %{enum: enum} do
      attrs = %{"enum_values" => []}

      assert {:error, changeset} = Enums.update_enum(enum, attrs)
      assert "must have at least one value" in errors_on(changeset).enum_values
    end

    test "duplicate name for same user fails", %{user: user, enum: enum} do
      insert(:enum_definition, user: user, name: "Taken")
      |> with_values(["x"])

      assert {:error, changeset} = Enums.update_enum(enum, %{"name" => "Taken"})
      assert "has already been taken" in errors_on(changeset).name
    end
  end

  # ── delete_enum/1 ─────────────────────────────────────────────

  describe "delete_enum/1" do
    setup [:create_user, :create_enum]

    test "deletes the enum and cascades to values", %{enum: enum} do
      value_ids = Enum.map(enum.enum_values, & &1.id)
      assert {:ok, _} = Enums.delete_enum(enum)

      assert_raise Ecto.NoResultsError, fn -> Repo.get!(UserEnum, enum.id) end

      for id <- value_ids do
        assert Repo.get(EnumValue, id) == nil
      end
    end
  end

  # ── list_user_enums/2 ────────────────────────────────────────

  describe "list_user_enums/2" do
    setup [:create_user]

    test "returns only the user's enums", %{user: user} do
      other_user = insert(:user)

      insert(:enum_definition, user: user, name: "Mine") |> with_values(["a"])
      insert(:enum_definition, user: other_user, name: "NotMine") |> with_values(["b"])

      enums = Enums.list_user_enums(user.id)
      assert length(enums) == 1
      assert hd(enums).name == "Mine"
    end

    test "preloads enum_values", %{user: user} do
      insert(:enum_definition, user: user) |> with_values(["x", "y"])

      [enum] = Enums.list_user_enums(user.id)
      assert length(enum.enum_values) == 2
    end

    test "orders by name ascending", %{user: user} do
      insert(:enum_definition, user: user, name: "Zebra") |> with_values(["z"])
      insert(:enum_definition, user: user, name: "Alpha") |> with_values(["a"])

      enums = Enums.list_user_enums(user.id)
      names = Enum.map(enums, & &1.name)
      assert names == ["Alpha", "Zebra"]
    end

    test "search filters by name (case-insensitive)", %{user: user} do
      insert(:enum_definition, user: user, name: "Colors") |> with_values(["red"])
      insert(:enum_definition, user: user, name: "Statuses") |> with_values(["active"])

      assert [enum] = Enums.list_user_enums(user.id, search: "color")
      assert enum.name == "Colors"

      assert [enum] = Enums.list_user_enums(user.id, search: "STATUS")
      assert enum.name == "Statuses"
    end

    test "search with no match returns empty list", %{user: user} do
      insert(:enum_definition, user: user, name: "Colors") |> with_values(["red"])

      assert [] = Enums.list_user_enums(user.id, search: "nonexistent")
    end

    test "empty search returns all", %{user: user} do
      insert(:enum_definition, user: user, name: "A") |> with_values(["a"])
      insert(:enum_definition, user: user, name: "B") |> with_values(["b"])

      assert length(Enums.list_user_enums(user.id, search: "")) == 2
      assert length(Enums.list_user_enums(user.id, search: nil)) == 2
    end
  end

  # ── get_user_enum!/2 ─────────────────────────────────────────

  describe "get_user_enum!/2" do
    setup [:create_user, :create_enum]

    test "returns the enum for the correct user", %{user: user, enum: enum} do
      result = Enums.get_user_enum!(user.id, enum.id)
      assert result.id == enum.id
      assert result.user_id == user.id
    end

    test "preloads enum_values", %{user: user, enum: enum} do
      result = Enums.get_user_enum!(user.id, enum.id)
      assert length(result.enum_values) == 3
    end

    test "raises if enum belongs to another user", %{enum: enum} do
      other_user = insert(:user)

      assert_raise Ecto.NoResultsError, fn ->
        Enums.get_user_enum!(other_user.id, enum.id)
      end
    end

    test "raises if enum does not exist", %{user: user} do
      assert_raise Ecto.NoResultsError, fn ->
        Enums.get_user_enum!(user.id, -1)
      end
    end
  end

  # ── get_enum!/1 ──────────────────────────────────────────────

  describe "get_enum!/1" do
    setup [:create_user, :create_enum]

    test "returns enum by id with preloaded values", %{enum: enum} do
      result = Enums.get_enum!(enum.id)
      assert result.id == enum.id
      assert length(result.enum_values) == 3
    end

    test "raises if not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Enums.get_enum!(-1)
      end
    end
  end

  # ── change_enum/2 ────────────────────────────────────────────

  describe "change_enum/2" do
    setup [:create_user, :create_enum]

    test "returns a changeset", %{enum: enum} do
      changeset = Enums.change_enum(enum)
      assert %Ecto.Changeset{} = changeset
    end

    test "changeset with valid attrs is valid", %{enum: enum} do
      changeset = Enums.change_enum(enum, %{"name" => "NewName"})
      assert changeset.valid?
    end
  end
end
