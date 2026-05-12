defmodule DataGenerator.Generator.Types.FloatGen do
  @moduledoc """
  Generates random floating-point values within a configurable range and precision.
  """

  @default_min 0.0
  @default_max 1_000_000.0
  @default_precision 2

  @doc """
  Generates `count` random floats.

  Config options:
    - `"min"` — minimum value (default: #{@default_min})
    - `"max"` — maximum value (default: #{@default_max})
    - `"precision"` — decimal places (default: #{@default_precision})
  """
  def generate(config, count) do
    min = get_float(config, "min", @default_min)
    max = get_float(config, "max", @default_max)
    precision = get_int(config, "precision", @default_precision)

    Enum.map(1..count, fn _ ->
      value = min + :rand.uniform() * (max - min)
      Float.round(value, precision)
    end)
  end

  defp get_float(config, key, default) do
    case Map.get(config, key) do
      nil -> default
      val when is_float(val) -> val
      val when is_integer(val) -> val / 1
      val when is_binary(val) -> String.to_float(val)
    end
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
