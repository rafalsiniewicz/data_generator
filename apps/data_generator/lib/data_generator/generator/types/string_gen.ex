defmodule DataGenerator.Generator.Types.StringGen do
  @moduledoc """
  Generates random string values with configurable length and optional prefix.
  """

  @default_length 10
  @charset ~c"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

  @doc """
  Generates `count` random strings.

  Config options:
    - `"length"` — character count (default: #{@default_length})
    - `"prefix"` — optional prefix prepended to each string
  """
  def generate(config, count) do
    length = get_int(config, "length", @default_length)
    prefix = Map.get(config, "prefix", "")

    Enum.map(1..count, fn _ ->
      random_part =
        Enum.map(1..length, fn _ ->
          Enum.random(@charset)
        end)
        |> List.to_string()

      prefix <> random_part
    end)
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
