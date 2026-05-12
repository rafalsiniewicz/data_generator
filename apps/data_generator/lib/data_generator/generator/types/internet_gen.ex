defmodule DataGenerator.Generator.Types.InternetGen do
  @moduledoc """
  Generates internet-related data values: URLs, IP addresses, and domain names.
  Uses the Faker library.
  """

  @doc """
  Generates `count` internet data values based on the subtype.

  Config options:
    - `"subtype"` — one of `"url"`, `"ip_address"`, `"domain"`
  """
  def generate(config, count) do
    subtype = Map.get(config, "subtype", "url")

    Enum.map(1..count, fn _ ->
      generate_value(subtype)
    end)
  end

  defp generate_value("url"), do: Faker.Internet.url()
  defp generate_value("ip_address"), do: Faker.Internet.ip_v4_address()
  defp generate_value("domain"), do: Faker.Internet.domain_name()
  defp generate_value(other), do: raise("Unknown internet subtype: #{other}")
end
