defmodule DataGenerator.Generator.Types.IntegerGenTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Generator.Types.IntegerGen

  describe "generate/2" do
    test "generates the correct number of values" do
      result = IntegerGen.generate(%{}, 10)
      assert length(result) == 10
    end

    test "generates integers within default range" do
      result = IntegerGen.generate(%{}, 100)

      Enum.each(result, fn val ->
        assert is_integer(val)
        assert val >= 0
        assert val <= 1_000_000
      end)
    end

    test "generates integers within custom range" do
      config = %{"min" => 5, "max" => 10}
      result = IntegerGen.generate(config, 100)

      Enum.each(result, fn val ->
        assert val >= 5
        assert val <= 10
      end)
    end

    test "handles string config values" do
      config = %{"min" => "1", "max" => "5"}
      result = IntegerGen.generate(config, 50)

      Enum.each(result, fn val ->
        assert val >= 1
        assert val <= 5
      end)
    end

    test "handles float config values by truncating" do
      config = %{"min" => 2.9, "max" => 7.1}
      result = IntegerGen.generate(config, 50)

      Enum.each(result, fn val ->
        assert val >= 2
        assert val <= 7
      end)
    end

    test "generates single value when min equals max" do
      config = %{"min" => 42, "max" => 42}
      result = IntegerGen.generate(config, 10)

      Enum.each(result, fn val ->
        assert val == 42
      end)
    end
  end
end
