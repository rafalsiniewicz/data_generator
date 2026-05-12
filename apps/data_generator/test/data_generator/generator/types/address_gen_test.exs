defmodule DataGenerator.Generator.Types.AddressGenTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Generator.Types.AddressGen

  describe "generate/2 with city subtype" do
    test "generates the correct number of values" do
      result = AddressGen.generate(%{"subtype" => "city"}, 10)
      assert length(result) == 10
    end

    test "generates non-empty strings" do
      result = AddressGen.generate(%{"subtype" => "city"}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert String.length(val) > 0
      end)
    end
  end

  describe "generate/2 with country subtype" do
    test "generates non-empty strings" do
      result = AddressGen.generate(%{"subtype" => "country"}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert String.length(val) > 0
      end)
    end
  end

  describe "generate/2 with street subtype" do
    test "generates non-empty strings" do
      result = AddressGen.generate(%{"subtype" => "street"}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert String.length(val) > 0
      end)
    end
  end

  describe "generate/2 with zip_code subtype" do
    test "generates non-empty strings" do
      result = AddressGen.generate(%{"subtype" => "zip_code"}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert String.length(val) > 0
      end)
    end
  end

  describe "generate/2 with unknown subtype" do
    test "raises for unknown subtype" do
      assert_raise RuntimeError, ~r/Unknown address subtype/, fn ->
        AddressGen.generate(%{"subtype" => "invalid"}, 1)
      end
    end
  end
end
