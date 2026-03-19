defmodule DataGenerator.Generator.Types.DateTimeGen do
  @moduledoc """
  Generates random datetime values within a configurable range.
  """

  @default_from "2020-01-01T00:00:00Z"
  @default_to "2025-12-31T23:59:59Z"

  @doc """
  Generates `count` random datetimes.

  Config options:
    - `"from"` — start datetime string in ISO 8601 format (default: #{@default_from})
    - `"to"` — end datetime string in ISO 8601 format (default: #{@default_to})
  """
  def generate(config, count) do
    from_str = Map.get(config, "from", @default_from)
    to_str = Map.get(config, "to", @default_to)

    {:ok, from_dt, _} = DateTime.from_iso8601(from_str)
    {:ok, to_dt, _} = DateTime.from_iso8601(to_str)

    from_unix = DateTime.to_unix(from_dt)
    to_unix = DateTime.to_unix(to_dt)

    Enum.map(1..count, fn _ ->
      random_unix = Enum.random(from_unix..to_unix)

      random_unix
      |> DateTime.from_unix!()
      |> DateTime.to_iso8601()
    end)
  end
end
