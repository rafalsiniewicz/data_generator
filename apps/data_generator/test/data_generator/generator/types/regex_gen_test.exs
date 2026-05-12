defmodule DataGenerator.Generator.Types.RegexGenTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Generator.Types.RegexGen

  describe "generate/2" do
    test "generates the correct number of values" do
      result = RegexGen.generate(%{"pattern" => "[a-z]{5}"}, 10)
      assert length(result) == 10
    end

    test "generates strings matching simple lowercase pattern" do
      pattern = "[a-z]{5}"
      result = RegexGen.generate(%{"pattern" => pattern}, 100)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert Regex.match?(~r/^[a-z]{5}$/, val)
      end)
    end

    test "generates strings matching uppercase pattern" do
      pattern = "[A-Z]{3}"
      result = RegexGen.generate(%{"pattern" => pattern}, 100)

      Enum.each(result, fn val ->
        assert Regex.match?(~r/^[A-Z]{3}$/, val)
      end)
    end

    test "generates strings matching digit pattern" do
      pattern = "\\d{4}"
      result = RegexGen.generate(%{"pattern" => pattern}, 100)

      Enum.each(result, fn val ->
        assert Regex.match?(~r/^\d{4}$/, val)
      end)
    end

    test "generates strings matching word character pattern" do
      pattern = "\\w{8}"
      result = RegexGen.generate(%{"pattern" => pattern}, 100)

      Enum.each(result, fn val ->
        assert Regex.match?(~r/^\w{8}$/, val)
      end)
    end

    test "generates strings matching mixed literal and class pattern" do
      pattern = "ID-[A-Z]{3}-\\d{4}"
      result = RegexGen.generate(%{"pattern" => pattern}, 100)

      Enum.each(result, fn val ->
        assert Regex.match?(~r/^ID-[A-Z]{3}-\d{4}$/, val)
      end)
    end

    test "generates strings matching range quantifier {n,m}" do
      pattern = "[a-z]{2,5}"
      result = RegexGen.generate(%{"pattern" => pattern}, 100)

      Enum.each(result, fn val ->
        len = String.length(val)
        assert len >= 2 and len <= 5
        assert Regex.match?(~r/^[a-z]+$/, val)
      end)
    end

    test "handles + quantifier (1-5 repetitions)" do
      pattern = "[0-9]+"
      result = RegexGen.generate(%{"pattern" => pattern}, 100)

      Enum.each(result, fn val ->
        len = String.length(val)
        assert len >= 1 and len <= 5
        assert Regex.match?(~r/^[0-9]+$/, val)
      end)
    end

    test "handles * quantifier (0-5 repetitions)" do
      pattern = "[a-z]*"
      result = RegexGen.generate(%{"pattern" => pattern}, 100)

      Enum.each(result, fn val ->
        len = String.length(val)
        assert len >= 0 and len <= 5
        if len > 0, do: assert(Regex.match?(~r/^[a-z]+$/, val))
      end)
    end

    test "handles ? quantifier (0-1 repetitions)" do
      pattern = "a?"
      result = RegexGen.generate(%{"pattern" => pattern}, 100)

      Enum.each(result, fn val ->
        assert val in ["", "a"]
      end)
    end

    test "uses default pattern when none specified" do
      result = RegexGen.generate(%{}, 50)

      Enum.each(result, fn val ->
        assert Regex.match?(~r/^[a-z]{10}$/, val)
      end)
    end

    test "generates strings matching character set pattern" do
      pattern = "[abc]{5}"
      result = RegexGen.generate(%{"pattern" => pattern}, 100)

      Enum.each(result, fn val ->
        assert String.length(val) == 5
        assert Regex.match?(~r/^[abc]{5}$/, val)
      end)
    end
  end
end
