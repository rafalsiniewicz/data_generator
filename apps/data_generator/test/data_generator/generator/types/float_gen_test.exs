defmodule DataGenerator.Generator.Types.FloatGenTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Generator.Types.FloatGen

  describe "generate/2" do
    test "generates the correct number of values" do
      result = FloatGen.generate(%{}, 10)
      assert length(result) == 10
    end

    test "generates floats within default range" do
      result = FloatGen.generate(%{}, 100)

      Enum.each(result, fn val ->
        assert is_float(val)
        assert val >= 0.0
        assert val <= 1_000_000.0
      end)
    end

    test "generates floats within custom range" do
      config = %{"min" => 1.0, "max" => 2.0}
      result = FloatGen.generate(config, 100)

      Enum.each(result, fn val ->
        assert val >= 1.0
        assert val <= 2.0
      end)
    end

    test "respects precision config" do
      config = %{"min" => 0.0, "max" => 100.0, "precision" => 3}
      result = FloatGen.generate(config, 100)

      Enum.each(result, fn val ->
        # Float.round with precision 3 means at most 3 decimal places
        assert val == Float.round(val, 3)
      end)
    end

    test "default precision is 2" do
      result = FloatGen.generate(%{"min" => 0.0, "max" => 100.0}, 100)

      Enum.each(result, fn val ->
        assert val == Float.round(val, 2)
      end)
    end

    test "handles string config values" do
      config = %{"min" => "1.0", "max" => "5.0", "precision" => "1"}
      result = FloatGen.generate(config, 50)

      Enum.each(result, fn val ->
        assert val >= 1.0
        assert val <= 5.0
      end)
    end

    test "handles integer config values for min/max" do
      config = %{"min" => 1, "max" => 5}
      result = FloatGen.generate(config, 50)

      Enum.each(result, fn val ->
        assert is_float(val)
        assert val >= 1.0
        assert val <= 5.0
      end)
    end
  end
end
