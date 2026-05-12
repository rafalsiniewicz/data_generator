defmodule DataGenerator.Generator.Types.EnumGen do
  @moduledoc """
  Generates values by randomly picking from a provided list of enum values.
  """

  @doc """
  Generates `count` values by randomly selecting from the provided values list.

  Config options:
    - `"values"` — list of possible values to choose from (required)
  """
  def generate(config, count) do
    values = Map.get(config, "values", [])

    if values == [] do
      raise "EnumGen requires a non-empty 'values' list in config"
    end

    Enum.map(1..count, fn _ -> Enum.random(values) end)
  end
end
