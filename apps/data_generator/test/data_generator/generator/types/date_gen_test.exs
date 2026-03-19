defmodule DataGenerator.Generator.Types.DateGenTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Generator.Types.DateGen

  describe "generate/2" do
    test "generates the correct number of values" do
      result = DateGen.generate(%{}, 10)
      assert length(result) == 10
    end

    test "generates valid ISO 8601 date strings" do
      result = DateGen.generate(%{}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert {:ok, _date} = Date.from_iso8601(val)
      end)
    end

    test "generates dates within default range" do
      result = DateGen.generate(%{}, 100)
      from = Date.from_iso8601!("2020-01-01")
      to = Date.from_iso8601!("2025-12-31")

      Enum.each(result, fn val ->
        date = Date.from_iso8601!(val)
        assert Date.compare(date, from) in [:gt, :eq]
        assert Date.compare(date, to) in [:lt, :eq]
      end)
    end

    test "generates dates within custom range" do
      config = %{"from" => "2024-06-01", "to" => "2024-06-30"}
      result = DateGen.generate(config, 100)

      from = Date.from_iso8601!("2024-06-01")
      to = Date.from_iso8601!("2024-06-30")

      Enum.each(result, fn val ->
        date = Date.from_iso8601!(val)
        assert Date.compare(date, from) in [:gt, :eq]
        assert Date.compare(date, to) in [:lt, :eq]
      end)
    end

    test "generates single date when from equals to" do
      config = %{"from" => "2024-01-15", "to" => "2024-01-15"}
      result = DateGen.generate(config, 10)

      Enum.each(result, fn val ->
        assert val == "2024-01-15"
      end)
    end
  end
end
