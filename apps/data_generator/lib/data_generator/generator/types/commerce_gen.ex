defmodule DataGenerator.Generator.Types.CommerceGen do
  @moduledoc """
  Generates commerce-related data values: prices, product names, and company names.
  Uses the Faker library.
  """

  @doc """
  Generates `count` commerce data values based on the subtype.

  Config options:
    - `"subtype"` — one of `"price"`, `"product_name"`, `"company"`
    - `"currency"` — optional currency prefix for prices (e.g. "USD", "$")
  """
  def generate(config, count) do
    subtype = Map.get(config, "subtype", "price")

    Enum.map(1..count, fn _ ->
      generate_value(subtype, config)
    end)
  end

  defp generate_value("price", config) do
    currency = Map.get(config, "currency", "")
    value = :rand.uniform() * 999.99 + 0.01
    rounded = Float.round(value, 2)

    if currency == "" do
      rounded
    else
      formatted = :erlang.float_to_binary(rounded, decimals: 2)
      "#{currency}#{formatted}"
    end
  end

  defp generate_value("product_name", _config), do: Faker.Commerce.product_name()
  defp generate_value("company", _config), do: Faker.Company.name()
  defp generate_value(other, _config), do: raise("Unknown commerce subtype: #{other}")
end
