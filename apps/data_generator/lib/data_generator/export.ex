defmodule DataGenerator.Export do
  @moduledoc """
  Dispatcher module for data export. Routes export requests to the
  appropriate format-specific module.
  """

  alias DataGenerator.Export.CSV
  alias DataGenerator.Export.JSON
  alias DataGenerator.Export.SQL

  @doc """
  Exports the given data in the specified format.

  Supported formats: `"csv"`, `"json"`, `"sql"`.

  Returns the formatted string.
  """
  def export(data, format, opts \\ [])

  def export(data, "csv", opts), do: {:ok, CSV.generate(data, opts)}
  def export(data, "json", opts), do: {:ok, JSON.generate(data, opts)}
  def export(data, "sql", opts), do: {:ok, SQL.generate(data, opts)}
  def export(_data, format, _opts), do: {:error, "Unsupported export format: #{format}"}
end
