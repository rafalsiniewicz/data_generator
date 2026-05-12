defmodule DataGenerator.Export.CSV do
  @moduledoc """
  Generates CSV output from a list of row maps.
  """

  @doc """
  Generates a CSV string from the given data.

  Data is expected as a list of maps with consistent keys.
  Columns appear in the order of the first row's keys.
  """
  def generate(data, _opts) when is_list(data) and length(data) > 0 do
    headers = data |> hd() |> Map.keys()

    header_row = Enum.join(headers, ",")

    data_rows =
      Enum.map(data, fn row ->
        headers
        |> Enum.map(fn key -> escape_csv_value(Map.get(row, key)) end)
        |> Enum.join(",")
      end)

    [header_row | data_rows]
    |> Enum.join("\n")
  end

  def generate([], _opts), do: ""

  defp escape_csv_value(nil), do: ""

  defp escape_csv_value(value) when is_binary(value) do
    if String.contains?(value, [",", "\"", "\n", "\r"]) do
      "\"" <> String.replace(value, "\"", "\"\"") <> "\""
    else
      value
    end
  end

  defp escape_csv_value(value), do: to_string(value)
end
