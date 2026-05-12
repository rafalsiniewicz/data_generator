defmodule DataGenerator.Generator.Types.DateTimeGen do
  @moduledoc """
  Generates random datetime values within a configurable range and timezone.
  """

  @default_from "2020-01-01T00:00:00Z"
  @default_to "2025-12-31T23:59:59Z"

  @doc """
  Generates `count` random datetimes.

  Config options:
    - `"from"` — start datetime string in ISO 8601 format (default: #{@default_from})
    - `"to"` — end datetime string in ISO 8601 format (default: #{@default_to})
    - `"timezone"` — UTC offset string like "UTC", "+05:30", "-08:00" (default: "UTC")
  """
  def generate(config, count) do
    from_str = Map.get(config, "from", @default_from) |> ensure_utc_suffix()
    to_str = Map.get(config, "to", @default_to) |> ensure_utc_suffix()
    timezone = Map.get(config, "timezone", "UTC")

    {:ok, from_dt, _} = DateTime.from_iso8601(from_str)
    {:ok, to_dt, _} = DateTime.from_iso8601(to_str)

    from_unix = DateTime.to_unix(from_dt)
    to_unix = DateTime.to_unix(to_dt)

    Enum.map(1..count, fn _ ->
      random_unix = Enum.random(from_unix..to_unix)
      dt = DateTime.from_unix!(random_unix)
      format_with_timezone(dt, timezone)
    end)
  end

  defp ensure_utc_suffix(str) do
    if String.ends_with?(str, "Z") or Regex.match?(~r/[+-]\d{2}:\d{2}$/, str) do
      str
    else
      str <> "Z"
    end
  end

  defp format_with_timezone(dt, "UTC"), do: DateTime.to_iso8601(dt)

  defp format_with_timezone(dt, offset) do
    {offset_seconds, _} = parse_offset(offset)
    shifted = DateTime.add(dt, offset_seconds, :second)
    Calendar.strftime(shifted, "%Y-%m-%dT%H:%M:%S") <> offset
  end

  defp parse_offset(offset) do
    case Regex.run(~r/^([+-])(\d{2}):(\d{2})$/, offset) do
      [_, sign, hours_str, mins_str] ->
        hours = String.to_integer(hours_str)
        mins = String.to_integer(mins_str)
        total = hours * 3600 + mins * 60
        total = if sign == "-", do: -total, else: total
        {total, offset}

      _ ->
        {0, "+00:00"}
    end
  end
end
