defmodule DataGenerator.Generator.Types.DateGen do
  @moduledoc """
  Generates random date values within a configurable range.
  """

  @default_from "2020-01-01"
  @default_to "2025-12-31"

  @doc """
  Generates `count` random dates.

  Config options:
    - `"from"` — start date string in ISO 8601 format (default: #{@default_from})
    - `"to"` — end date string in ISO 8601 format (default: #{@default_to})
    - `"timezone"` — stored for reference but dates are timezone-agnostic (default: "UTC")
  """
  def generate(config, count) do
    from_str = Map.get(config, "from", @default_from)
    to_str = Map.get(config, "to", @default_to)
    timezone = Map.get(config, "timezone", "UTC")

    from_date = Date.from_iso8601!(from_str)
    to_date = Date.from_iso8601!(to_str)

    from_days = Date.to_gregorian_days(from_date)
    to_days = Date.to_gregorian_days(to_date)

    suffix = timezone_suffix(timezone)

    Enum.map(1..count, fn _ ->
      random_days = Enum.random(from_days..to_days)
      Date.from_gregorian_days(random_days) |> Date.to_iso8601() |> Kernel.<>(suffix)
    end)
  end

  defp timezone_suffix("UTC"), do: ""
  defp timezone_suffix(offset), do: " (#{offset})"
end
