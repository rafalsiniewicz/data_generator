defmodule DataGenerator.Generator.Types.UUIDGenTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Generator.Types.UUIDGen

  @uuid_regex ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

  describe "generate/2" do
    test "generates the correct number of values" do
      result = UUIDGen.generate(%{}, 10)
      assert length(result) == 10
    end

    test "generates valid UUID v4 format strings" do
      result = UUIDGen.generate(%{}, 100)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert Regex.match?(@uuid_regex, val)
      end)
    end

    test "generates unique UUIDs" do
      result = UUIDGen.generate(%{}, 100)
      assert length(Enum.uniq(result)) == 100
    end

    test "ignores config options" do
      result = UUIDGen.generate(%{"irrelevant" => "option"}, 5)
      assert length(result) == 5

      Enum.each(result, fn val ->
        assert Regex.match?(@uuid_regex, val)
      end)
    end
  end
end
