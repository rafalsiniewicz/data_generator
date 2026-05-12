defmodule DataGenerator.Generator.Types.CommerceGenTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Generator.Types.CommerceGen

  describe "generate/2 with price subtype" do
    test "generates the correct number of values" do
      result = CommerceGen.generate(%{"subtype" => "price"}, 10)
      assert length(result) == 10
    end

    test "generates positive float prices" do
      result = CommerceGen.generate(%{"subtype" => "price"}, 100)

      Enum.each(result, fn val ->
        assert is_float(val)
        assert val > 0.0
        assert val <= 1000.0
      end)
    end

    test "prices have at most 2 decimal places" do
      result = CommerceGen.generate(%{"subtype" => "price"}, 100)

      Enum.each(result, fn val ->
        assert val == Float.round(val, 2)
      end)
    end
  end

  describe "generate/2 with product_name subtype" do
    test "generates non-empty strings" do
      result = CommerceGen.generate(%{"subtype" => "product_name"}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert String.length(val) > 0
      end)
    end
  end

  describe "generate/2 with company subtype" do
    test "generates non-empty strings" do
      result = CommerceGen.generate(%{"subtype" => "company"}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert String.length(val) > 0
      end)
    end
  end

  describe "generate/2 with unknown subtype" do
    test "raises for unknown subtype" do
      assert_raise RuntimeError, ~r/Unknown commerce subtype/, fn ->
        CommerceGen.generate(%{"subtype" => "invalid"}, 1)
      end
    end
  end
end
