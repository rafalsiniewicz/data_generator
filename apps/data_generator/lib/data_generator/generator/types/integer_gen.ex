defmodule DataGenerator.Generator.Types.IntegerGen do
  @moduledoc """
  Generates random integer values within a configurable range.
  """

  @default_min 0
  @default_max 1_000_000

  @doc """
  Generates `count` random integers.

  Config options:
    - `"min"` — minimum value (default: #{@default_min})
    - `"max"` — maximum value (default: #{@default_max})
  """
  def generate(config, count) do
    min = get_int(config, "min", @default_min)
    max = get_int(config, "max", @default_max)

    Enum.map(1..count, fn _ -> Enum.random(min..max) end)
  end

  defp get_int(config, key, default) do
    case Map.get(config, key) do
      nil -> default
      val when is_integer(val) -> val
      val when is_binary(val) -> String.to_integer(val)
      val when is_float(val) -> trunc(val)
    end
  end
end
