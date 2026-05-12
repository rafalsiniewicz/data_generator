defmodule DataGenerator.Generator.Engine do
  @moduledoc """
  Core data generation engine. Takes a list of column definitions and
  a row count, generates values for each column in parallel, and zips
  the results into a list of row maps.
  """

  alias DataGenerator.Generator.Types.{
    IntegerGen,
    FloatGen,
    StringGen,
    BooleanGen,
    DateGen,
    DateTimeGen,
    UUIDGen,
    PersonalGen,
    AddressGen,
    InternetGen,
    CommerceGen,
    RegexGen,
    EnumGen
  }

  @chunk_size 1000

  @doc """
  Generates data for the given columns and row count.

  For row_count > 10,000, processes in chunks of 1,000 rows.
  Returns `{:ok, [%{col_name => value, ...}]}` or `{:error, reason}`.
  """
  def generate(columns, row_count) when is_integer(row_count) and row_count > 0 do
    if row_count > 10_000 do
      generate_chunked(columns, row_count)
    else
      generate_batch(columns, row_count)
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  def generate(_columns, _row_count), do: {:error, "row_count must be a positive integer"}

  defp generate_chunked(columns, row_count) do
    chunk_sizes =
      0..(row_count - 1)
      |> Enum.chunk_every(@chunk_size)
      |> Enum.map(&length/1)

    Enum.reduce_while(chunk_sizes, {:ok, []}, fn chunk_size, {:ok, acc} ->
      case generate_batch(columns, chunk_size) do
        {:ok, chunk_rows} -> {:cont, {:ok, acc ++ chunk_rows}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp generate_batch(columns, row_count) do
    results =
      Task.Supervisor.async_stream_nolink(
        DataGenerator.Generator.TaskSupervisor,
        columns,
        fn column ->
          type_name = resolve_type_name(column)
          config = resolve_config(column)
          values = generate_column_values(type_name, config, row_count)
          {column_name(column), values}
        end,
        timeout: :infinity,
        ordered: true
      )
      |> Enum.reduce_while([], fn
        {:ok, result}, acc -> {:cont, [result | acc]}
        {:exit, reason}, _acc -> {:halt, {:error, "Column generation failed: #{inspect(reason)}"}}
      end)

    case results do
      {:error, _} = error ->
        error

      column_results when is_list(column_results) ->
        rows = zip_columns_to_rows(Enum.reverse(column_results), row_count)
        {:ok, rows}
    end
  end

  defp zip_columns_to_rows(column_results, row_count) do
    # Convert value lists to tuples for O(1) access by index
    column_tuples =
      Enum.map(column_results, fn {col_name, values} ->
        {col_name, List.to_tuple(values)}
      end)

    Enum.map(0..(row_count - 1), fn row_index ->
      Enum.into(column_tuples, %{}, fn {col_name, values_tuple} ->
        {col_name, elem(values_tuple, row_index)}
      end)
    end)
  end

  defp resolve_type_name(%{type: %{name: name}}), do: name
  defp resolve_type_name(%{type_name: name}), do: name
  defp resolve_type_name(%{"type_name" => name}), do: name
  defp resolve_type_name(%{"type" => %{"name" => name}}), do: name
  defp resolve_type_name(_), do: raise("Cannot resolve type name from column definition")

  defp resolve_config(%{config: config}) when is_map(config), do: config
  defp resolve_config(%{"config" => config}) when is_map(config), do: config
  defp resolve_config(_), do: %{}

  defp column_name(%{name: name}), do: name
  defp column_name(%{"name" => name}), do: name

  defp generate_column_values(type_name, config, count) do
    case type_name do
      "integer" -> IntegerGen.generate(config, count)
      "float" -> FloatGen.generate(config, count)
      "string" -> StringGen.generate(config, count)
      "boolean" -> BooleanGen.generate(config, count)
      "date" -> DateGen.generate(config, count)
      "datetime" -> DateTimeGen.generate(config, count)
      "uuid" -> UUIDGen.generate(config, count)
      "first_name" -> PersonalGen.generate(Map.put(config, "subtype", "first_name"), count)
      "last_name" -> PersonalGen.generate(Map.put(config, "subtype", "last_name"), count)
      "email" -> PersonalGen.generate(Map.put(config, "subtype", "email"), count)
      "phone" -> PersonalGen.generate(Map.put(config, "subtype", "phone"), count)
      "city" -> AddressGen.generate(Map.put(config, "subtype", "city"), count)
      "country" -> AddressGen.generate(Map.put(config, "subtype", "country"), count)
      "street" -> AddressGen.generate(Map.put(config, "subtype", "street"), count)
      "zip_code" -> AddressGen.generate(Map.put(config, "subtype", "zip_code"), count)
      "url" -> InternetGen.generate(Map.put(config, "subtype", "url"), count)
      "ip_address" -> InternetGen.generate(Map.put(config, "subtype", "ip_address"), count)
      "domain" -> InternetGen.generate(Map.put(config, "subtype", "domain"), count)
      "price" -> CommerceGen.generate(Map.put(config, "subtype", "price"), count)
      "product_name" -> CommerceGen.generate(Map.put(config, "subtype", "product_name"), count)
      "company" -> CommerceGen.generate(Map.put(config, "subtype", "company"), count)
      "regex" -> RegexGen.generate(config, count)
      "enum" -> EnumGen.generate(config, count)
      other -> raise "Unknown type: #{other}"
    end
  end
end
