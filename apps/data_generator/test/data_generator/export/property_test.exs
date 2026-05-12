defmodule DataGenerator.Export.PropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias DataGenerator.Export.CSV
  alias DataGenerator.Export.JSON
  alias DataGenerator.Export.SQL

  describe "CSV property" do
    property "CSV has length(data) + 1 lines for non-empty data" do
      check all(
              count <- integer(1..20),
              keys <-
                list_of(string(:alphanumeric, min_length: 1, max_length: 10),
                  min_length: 1,
                  max_length: 5
                )
            ) do
        keys = Enum.uniq(keys)

        data =
          Enum.map(1..count, fn i ->
            Enum.into(keys, %{}, fn key -> {key, "val_#{i}"} end)
          end)

        result = CSV.generate(data, [])
        lines = String.split(result, "\n")
        # header + data rows
        assert length(lines) == count + 1
      end
    end
  end

  describe "JSON property" do
    property "JSON decode roundtrips data correctly" do
      check all(
              count <- integer(1..10),
              keys <-
                list_of(string(:alphanumeric, min_length: 1, max_length: 10),
                  min_length: 1,
                  max_length: 5
                )
            ) do
        keys = Enum.uniq(keys)

        data =
          Enum.map(1..count, fn i ->
            Enum.into(keys, %{}, fn key -> {key, "val_#{i}"} end)
          end)

        result = JSON.generate(data, [])
        assert {:ok, decoded} = Jason.decode(result)
        assert decoded == data
      end
    end
  end

  describe "SQL property" do
    property "each line starts with INSERT INTO table_name for non-empty data" do
      check all(
              count <- integer(1..10),
              table_name <- string(:alphanumeric, min_length: 1, max_length: 20)
            ) do
        data =
          Enum.map(1..count, fn i ->
            %{"id" => i, "name" => "item_#{i}"}
          end)

        result = SQL.generate(data, table_name: table_name)
        lines = String.split(result, "\n")
        assert length(lines) == count

        Enum.each(lines, fn line ->
          assert String.starts_with?(
                   line,
                   "INSERT INTO \"#{String.replace(table_name, "\"", "\"\"")}\""
                 )
        end)
      end
    end
  end
end
