defmodule DataGenerator.Generator.Types.AddressGen do
  @moduledoc """
  Generates address-related data values: city, country, street, and zip code.
  Uses the Faker library.
  """

  @doc """
  Generates `count` address data values based on the subtype.

  Config options:
    - `"subtype"` — one of `"city"`, `"country"`, `"street"`, `"zip_code"`
  """
  def generate(config, count) do
    subtype = Map.get(config, "subtype", "city")

    Enum.map(1..count, fn _ ->
      generate_value(subtype)
    end)
  end

  defp generate_value("city"), do: Faker.Address.city()
  defp generate_value("country"), do: Faker.Address.country()
  defp generate_value("street"), do: Faker.Address.street_address()
  defp generate_value("zip_code"), do: Faker.Address.zip_code()
  defp generate_value(other), do: raise("Unknown address subtype: #{other}")
end
