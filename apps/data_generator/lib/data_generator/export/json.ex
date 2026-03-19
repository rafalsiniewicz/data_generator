defmodule DataGenerator.Export.JSON do
  @moduledoc """
  Generates JSON output from a list of row maps.
  """

  @doc """
  Generates a pretty-printed JSON string from the given data.
  """
  def generate(data, _opts) do
    Jason.encode!(data, pretty: true)
  end
end
