defmodule DataGenerator.Generator.Types.CommerceGen do
  @moduledoc """
  Generates commerce-related data values: prices, product names, and company names.
  Uses the Faker library.
  """

  @doc """
  Generates `count` commerce data values based on the subtype.

  Config options:
    - `"subtype"` — one of `"price"`, `"product_name"`, `"company"`
  """
  def generate(config, count) do
    subtype = Map.get(config, "subtype", "price")

    Enum.map(1..count, fn _ ->
      generate_value(subtype)
    end)
  end

  defp generate_value("price") do
    value = :rand.uniform() * 999.99 + 0.01
    Float.round(value, 2)
  end

  defp generate_value("product_name"), do: Faker.Commerce.product_name()
  defp generate_value("company"), do: Faker.Company.name()
  defp generate_value(other), do: raise("Unknown commerce subtype: #{other}")
end
