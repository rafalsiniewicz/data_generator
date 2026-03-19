defmodule DataGenerator.Generator.Types.PersonalGen do
  @moduledoc """
  Generates personal data values: first names, last names, emails, and phone numbers.
  Uses the Faker library.
  """

  @doc """
  Generates `count` personal data values based on the subtype.

  Config options:
    - `"subtype"` — one of `"first_name"`, `"last_name"`, `"email"`, `"phone"`
  """
  def generate(config, count) do
    subtype = Map.get(config, "subtype", "first_name")

    Enum.map(1..count, fn _ ->
      generate_value(subtype)
    end)
  end

  defp generate_value("first_name"), do: Faker.Person.first_name()
  defp generate_value("last_name"), do: Faker.Person.last_name()
  defp generate_value("email"), do: Faker.Internet.email()
  defp generate_value("phone"), do: Faker.Phone.EnUs.phone()
  defp generate_value(other), do: raise("Unknown personal subtype: #{other}")
end
