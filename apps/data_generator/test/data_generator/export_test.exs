defmodule DataGenerator.ExportTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Export
  alias DataGenerator.Export.CSV
  alias DataGenerator.Export.JSON
  alias DataGenerator.Export.SQL

  # ── CSV Tests ──────────────────────────────────────────────────

  describe "Export.CSV" do
    test "generates correct header row" do
      data = [%{"name" => "Alice", "age" => 30}]
      result = CSV.generate(data, [])
      [header | _] = String.split(result, "\n")
      assert "name" in String.split(header, ",")
      assert "age" in String.split(header, ",")
    end

    test "generates correct number of data rows" do
      data = [
        %{"name" => "Alice", "age" => 30},
        %{"name" => "Bob", "age" => 25},
        %{"name" => "Charlie", "age" => 35}
      ]

      result = CSV.generate(data, [])
      lines = String.split(result, "\n")
      # 1 header + 3 data rows
      assert length(lines) == 4
    end

    test "escapes values containing commas" do
      data = [%{"description" => "hello, world", "id" => 1}]
      result = CSV.generate(data, [])
      assert String.contains?(result, "\"hello, world\"")
    end

    test "escapes values containing double quotes" do
      data = [%{"text" => "say \"hi\"", "id" => 1}]
      result = CSV.generate(data, [])
      assert String.contains?(result, "\"say \"\"hi\"\"\"")
    end

    test "escapes values containing newlines" do
      data = [%{"text" => "line1\nline2", "id" => 1}]
      result = CSV.generate(data, [])
      assert String.contains?(result, "\"line1\nline2\"")
    end

    test "empty data returns empty string" do
      result = CSV.generate([], [])
      assert result == ""
    end

    test "nil values become empty strings" do
      data = [%{"name" => nil, "id" => 1}]
      result = CSV.generate(data, [])
      lines = String.split(result, "\n")
      # The data row should have an empty field for nil
      assert length(lines) == 2
    end
  end

  # ── JSON Tests ─────────────────────────────────────────────────

  describe "Export.JSON" do
    test "output is valid JSON array" do
      data = [%{"name" => "Alice"}, %{"name" => "Bob"}]
      result = JSON.generate(data, [])
      assert {:ok, decoded} = Jason.decode(result)
      assert is_list(decoded)
      assert length(decoded) == 2
    end

    test "each element has correct keys" do
      data = [
        %{"name" => "Alice", "age" => 30},
        %{"name" => "Bob", "age" => 25}
      ]

      result = JSON.generate(data, [])
      {:ok, decoded} = Jason.decode(result)

      Enum.each(decoded, fn item ->
        assert Map.has_key?(item, "name")
        assert Map.has_key?(item, "age")
      end)
    end

    test "handles unicode" do
      data = [%{"name" => "Renée", "city" => "Zürich"}]
      result = JSON.generate(data, [])
      {:ok, decoded} = Jason.decode(result)
      assert hd(decoded)["name"] == "Renée"
      assert hd(decoded)["city"] == "Zürich"
    end

    test "handles empty data" do
      result = JSON.generate([], [])
      {:ok, decoded} = Jason.decode(result)
      assert decoded == []
    end

    test "preserves data types" do
      data = [%{"count" => 42, "price" => 9.99, "active" => true, "name" => "test"}]
      result = JSON.generate(data, [])
      {:ok, [item]} = Jason.decode(result)
      assert item["count"] == 42
      assert item["price"] == 9.99
      assert item["active"] == true
      assert item["name"] == "test"
    end
  end

  # ── SQL Tests ──────────────────────────────────────────────────

  describe "Export.SQL" do
    test "generates valid INSERT syntax" do
      data = [%{"name" => "Alice", "age" => 30}]
      result = SQL.generate(data, [])
      assert String.starts_with?(result, "INSERT INTO")
      assert String.contains?(result, "VALUES")
      assert String.ends_with?(result, ";")
    end

    test "strings are single-quote escaped" do
      data = [%{"name" => "O'Brien"}]
      result = SQL.generate(data, [])
      assert String.contains?(result, "'O''Brien'")
    end

    test "NULL handling for nil values" do
      data = [%{"name" => nil}]
      result = SQL.generate(data, [])
      assert String.contains?(result, "NULL")
    end

    test "boolean values are TRUE/FALSE" do
      data = [%{"active" => true, "deleted" => false}]
      result = SQL.generate(data, [])
      assert String.contains?(result, "TRUE")
      assert String.contains?(result, "FALSE")
    end

    test "custom table name works" do
      data = [%{"id" => 1}]
      result = SQL.generate(data, table_name: "users")
      assert String.contains?(result, "\"users\"")
    end

    test "default table name is generated_data" do
      data = [%{"id" => 1}]
      result = SQL.generate(data, [])
      assert String.contains?(result, "\"generated_data\"")
    end

    test "generates one INSERT per row" do
      data = [
        %{"id" => 1, "name" => "Alice"},
        %{"id" => 2, "name" => "Bob"},
        %{"id" => 3, "name" => "Charlie"}
      ]

      result = SQL.generate(data, [])
      statements = String.split(result, "\n")
      assert length(statements) == 3

      Enum.each(statements, fn stmt ->
        assert String.starts_with?(stmt, "INSERT INTO")
      end)
    end

    test "empty data returns empty string" do
      result = SQL.generate([], [])
      assert result == ""
    end

    test "integer values are not quoted" do
      data = [%{"count" => 42}]
      result = SQL.generate(data, [])
      assert String.contains?(result, "42")
      refute String.contains?(result, "'42'")
    end

    test "float values are not quoted" do
      data = [%{"price" => 9.99}]
      result = SQL.generate(data, [])
      assert String.contains?(result, "9.99")
      refute String.contains?(result, "'9.99'")
    end

    test "column names are double-quote escaped" do
      data = [%{"user name" => "test"}]
      result = SQL.generate(data, [])
      assert String.contains?(result, "\"user name\"")
    end
  end

  # ── Export Dispatcher Tests ────────────────────────────────────

  describe "Export.export/3" do
    test "dispatches to CSV" do
      data = [%{"a" => 1}]
      assert {:ok, result} = Export.export(data, "csv")
      assert is_binary(result)
    end

    test "dispatches to JSON" do
      data = [%{"a" => 1}]
      assert {:ok, result} = Export.export(data, "json")
      assert {:ok, _} = Jason.decode(result)
    end

    test "dispatches to SQL" do
      data = [%{"a" => 1}]
      assert {:ok, result} = Export.export(data, "sql")
      assert String.contains?(result, "INSERT INTO")
    end

    test "returns error for unsupported format" do
      data = [%{"a" => 1}]
      assert {:error, msg} = Export.export(data, "xml")
      assert String.contains?(msg, "Unsupported")
    end
  end
end
