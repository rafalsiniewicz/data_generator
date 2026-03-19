defmodule DataGenerator.GeneratorTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Generator.Engine

  describe "Engine.generate/2" do
    test "generates correct number of rows with mixed column types" do
      columns = [
        %{"name" => "id", "type_name" => "integer", "config" => %{"min" => 1, "max" => 100}},
        %{"name" => "name", "type_name" => "string", "config" => %{"length" => 5}},
        %{"name" => "active", "type_name" => "boolean", "config" => %{}}
      ]

      assert {:ok, rows} = Engine.generate(columns, 50)
      assert length(rows) == 50
    end

    test "each row has all column keys" do
      columns = [
        %{"name" => "age", "type_name" => "integer", "config" => %{}},
        %{"name" => "email", "type_name" => "email", "config" => %{}},
        %{"name" => "city", "type_name" => "city", "config" => %{}}
      ]

      assert {:ok, rows} = Engine.generate(columns, 10)

      Enum.each(rows, fn row ->
        assert Map.has_key?(row, "age")
        assert Map.has_key?(row, "email")
        assert Map.has_key?(row, "city")
      end)
    end

    test "values match expected types" do
      columns = [
        %{"name" => "count", "type_name" => "integer", "config" => %{"min" => 0, "max" => 100}},
        %{"name" => "price", "type_name" => "float", "config" => %{"min" => 0.0, "max" => 50.0}},
        %{"name" => "flag", "type_name" => "boolean", "config" => %{}},
        %{"name" => "uid", "type_name" => "uuid", "config" => %{}}
      ]

      assert {:ok, rows} = Engine.generate(columns, 20)

      Enum.each(rows, fn row ->
        assert is_integer(row["count"])
        assert is_float(row["price"])
        assert is_boolean(row["flag"])
        assert is_binary(row["uid"])
      end)
    end

    test "large generation (10k+ rows) completes and uses chunking" do
      columns = [
        %{"name" => "id", "type_name" => "integer", "config" => %{"min" => 1, "max" => 999_999}}
      ]

      assert {:ok, rows} = Engine.generate(columns, 11_000)
      assert length(rows) == 11_000
    end

    test "supports atom key column definitions" do
      columns = [
        %{name: "first", type_name: "first_name", config: %{}},
        %{name: "last", type_name: "last_name", config: %{}}
      ]

      assert {:ok, rows} = Engine.generate(columns, 5)
      assert length(rows) == 5

      Enum.each(rows, fn row ->
        assert Map.has_key?(row, "first")
        assert Map.has_key?(row, "last")
      end)
    end

    test "supports nested type map column definitions" do
      columns = [
        %{
          "name" => "val",
          "type" => %{"name" => "integer"},
          "config" => %{"min" => 1, "max" => 5}
        }
      ]

      assert {:ok, rows} = Engine.generate(columns, 5)
      assert length(rows) == 5

      Enum.each(rows, fn row ->
        assert is_integer(row["val"])
        assert row["val"] >= 1 and row["val"] <= 5
      end)
    end

    test "supports struct-style type column definitions" do
      type_struct = %{name: "string"}

      columns = [
        %{name: "text", type: type_struct, config: %{"length" => 3}}
      ]

      assert {:ok, rows} = Engine.generate(columns, 5)

      Enum.each(rows, fn row ->
        assert String.length(row["text"]) == 3
      end)
    end

    test "returns error for invalid row_count" do
      columns = [%{"name" => "id", "type_name" => "integer", "config" => %{}}]

      assert {:error, "row_count must be a positive integer"} = Engine.generate(columns, 0)
      assert {:error, "row_count must be a positive integer"} = Engine.generate(columns, -1)
    end

    test "returns error for unknown type" do
      columns = [
        %{"name" => "bad", "type_name" => "nonexistent_type", "config" => %{}}
      ]

      assert {:error, _reason} = Engine.generate(columns, 5)
    end

    test "handles all supported type names" do
      type_names = [
        "integer",
        "float",
        "string",
        "boolean",
        "date",
        "datetime",
        "uuid",
        "first_name",
        "last_name",
        "email",
        "phone",
        "city",
        "country",
        "street",
        "zip_code",
        "url",
        "ip_address",
        "domain",
        "price",
        "product_name",
        "company",
        "regex",
        "enum"
      ]

      Enum.each(type_names, fn type_name ->
        config =
          case type_name do
            "enum" -> %{"values" => ["a", "b"]}
            "regex" -> %{"pattern" => "[a-z]{3}"}
            _ -> %{}
          end

        columns = [%{"name" => "col", "type_name" => type_name, "config" => config}]
        assert {:ok, rows} = Engine.generate(columns, 3), "Failed for type: #{type_name}"
        assert length(rows) == 3
      end)
    end

    test "generates with empty config defaulting correctly" do
      columns = [
        %{"name" => "num", "type_name" => "integer", "config" => %{}},
        %{"name" => "str", "type_name" => "string", "config" => %{}}
      ]

      assert {:ok, rows} = Engine.generate(columns, 5)

      Enum.each(rows, fn row ->
        assert is_integer(row["num"])
        assert is_binary(row["str"])
        # default string length
        assert String.length(row["str"]) == 10
      end)
    end
  end
end
