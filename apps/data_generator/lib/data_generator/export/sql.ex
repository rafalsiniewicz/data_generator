defmodule DataGenerator.Export.SQL do
  @moduledoc """
  Generates SQL INSERT statements from a list of row maps.
  """

  @doc """
  Generates SQL INSERT INTO statements from the given data.

  Columns appear in the order of the first row's keys.

  Options:
    - `:table_name` — the table name to use (default: `"generated_data"`)
  """
  def generate(data, opts) when is_list(data) and length(data) > 0 do
    table_name = Keyword.get(opts, :table_name, "generated_data")
    headers = data |> hd() |> Map.keys()
    quoted_columns = Enum.map(headers, &quote_identifier/1) |> Enum.join(", ")

    statements =
      Enum.map(data, fn row ->
        values =
          headers
          |> Enum.map(fn key -> escape_sql_value(Map.get(row, key)) end)
          |> Enum.join(", ")

        "INSERT INTO #{quote_identifier(table_name)} (#{quoted_columns}) VALUES (#{values});"
      end)

    Enum.join(statements, "\n")
  end

  def generate([], _opts), do: ""

  defp quote_identifier(name) when is_binary(name) do
    "\"" <> String.replace(name, "\"", "\"\"") <> "\""
  end

  defp quote_identifier(name), do: quote_identifier(to_string(name))

  defp escape_sql_value(nil), do: "NULL"

  defp escape_sql_value(value) when is_binary(value) do
    escaped = String.replace(value, "'", "''")
    "'#{escaped}'"
  end

  defp escape_sql_value(value) when is_integer(value), do: Integer.to_string(value)
  defp escape_sql_value(value) when is_float(value), do: Float.to_string(value)
  defp escape_sql_value(true), do: "TRUE"
  defp escape_sql_value(false), do: "FALSE"
  defp escape_sql_value(value), do: escape_sql_value(to_string(value))
end
