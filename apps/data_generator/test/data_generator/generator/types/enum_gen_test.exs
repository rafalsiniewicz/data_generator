defmodule DataGenerator.Generator.Types.EnumGenTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Generator.Types.EnumGen

  describe "generate/2" do
    test "generates the correct number of values" do
      config = %{"values" => ["red", "green", "blue"]}
      result = EnumGen.generate(config, 10)
      assert length(result) == 10
    end

    test "only picks from provided values" do
      values = ["red", "green", "blue"]
      config = %{"values" => values}
      result = EnumGen.generate(config, 100)

      Enum.each(result, fn val ->
        assert val in values
      end)
    end

    test "picks from single-element list" do
      config = %{"values" => ["only"]}
      result = EnumGen.generate(config, 10)

      Enum.each(result, fn val ->
        assert val == "only"
      end)
    end

    test "raises with empty values list" do
      assert_raise RuntimeError, ~r/non-empty/, fn ->
        EnumGen.generate(%{"values" => []}, 1)
      end
    end

    test "raises with missing values key" do
      assert_raise RuntimeError, ~r/non-empty/, fn ->
        EnumGen.generate(%{}, 1)
      end
    end

    test "distributes values roughly evenly over many samples" do
      values = ["a", "b", "c"]
      config = %{"values" => values}
      result = EnumGen.generate(config, 9000)

      counts =
        Enum.reduce(result, %{}, fn val, acc ->
          Map.update(acc, val, 1, &(&1 + 1))
        end)

      # Each value should appear roughly 3000 times (± 500)
      Enum.each(values, fn v ->
        count = Map.get(counts, v, 0)
        assert count > 2000, "#{v} appeared #{count} times, expected ~3000"
        assert count < 4000, "#{v} appeared #{count} times, expected ~3000"
      end)
    end
  end
end
