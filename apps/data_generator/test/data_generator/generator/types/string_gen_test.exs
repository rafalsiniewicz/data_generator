defmodule DataGenerator.Generator.Types.StringGenTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Generator.Types.StringGen

  describe "generate/2" do
    test "generates the correct number of values" do
      result = StringGen.generate(%{}, 10)
      assert length(result) == 10
    end

    test "generates strings of default length 10" do
      result = StringGen.generate(%{}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert String.length(val) == 10
      end)
    end

    test "generates strings of custom length" do
      config = %{"length" => 25}
      result = StringGen.generate(config, 50)

      Enum.each(result, fn val ->
        assert String.length(val) == 25
      end)
    end

    test "respects prefix config" do
      config = %{"prefix" => "test_", "length" => 5}
      result = StringGen.generate(config, 50)

      Enum.each(result, fn val ->
        assert String.starts_with?(val, "test_")
        # prefix "test_" (5 chars) + random part (5 chars) = 10 total
        assert String.length(val) == 10
      end)
    end

    test "generates only alphanumeric characters" do
      result = StringGen.generate(%{"length" => 100}, 10)

      Enum.each(result, fn val ->
        assert Regex.match?(~r/^[a-zA-Z0-9]+$/, val)
      end)
    end

    test "handles string config values for length" do
      config = %{"length" => "8"}
      result = StringGen.generate(config, 10)

      Enum.each(result, fn val ->
        assert String.length(val) == 8
      end)
    end
  end
end
