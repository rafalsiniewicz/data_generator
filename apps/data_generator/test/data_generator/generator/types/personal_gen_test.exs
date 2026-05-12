defmodule DataGenerator.Generator.Types.PersonalGenTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Generator.Types.PersonalGen

  describe "generate/2 with first_name subtype" do
    test "generates the correct number of values" do
      result = PersonalGen.generate(%{"subtype" => "first_name"}, 10)
      assert length(result) == 10
    end

    test "generates non-empty strings" do
      result = PersonalGen.generate(%{"subtype" => "first_name"}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert String.length(val) > 0
      end)
    end
  end

  describe "generate/2 with last_name subtype" do
    test "generates non-empty strings" do
      result = PersonalGen.generate(%{"subtype" => "last_name"}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert String.length(val) > 0
      end)
    end
  end

  describe "generate/2 with email subtype" do
    test "generates strings containing @" do
      result = PersonalGen.generate(%{"subtype" => "email"}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert String.contains?(val, "@")
      end)
    end
  end

  describe "generate/2 with phone subtype" do
    test "generates strings matching digit pattern" do
      result = PersonalGen.generate(%{"subtype" => "phone"}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        # Phone numbers should contain digits
        assert Regex.match?(~r/\d/, val)
      end)
    end
  end

  describe "generate/2 with default subtype" do
    test "defaults to first_name" do
      result = PersonalGen.generate(%{}, 10)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert String.length(val) > 0
      end)
    end
  end

  describe "generate/2 with unknown subtype" do
    test "raises for unknown subtype" do
      assert_raise RuntimeError, ~r/Unknown personal subtype/, fn ->
        PersonalGen.generate(%{"subtype" => "invalid"}, 1)
      end
    end
  end
end
