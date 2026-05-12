defmodule DataGenerator.Generator.Types.BooleanGen do
  @moduledoc """
  Generates random boolean values with a configurable true/false ratio.
  """

  @default_true_ratio 0.5

  @doc """
  Generates `count` random booleans.

  Config options:
    - `"true_ratio"` — probability of `true` (default: #{@default_true_ratio})
  """
  def generate(config, count) do
    true_ratio = get_float(config, "true_ratio", @default_true_ratio)

    Enum.map(1..count, fn _ ->
      :rand.uniform() < true_ratio
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
end
