defmodule DataGenerator.Generator.Types.InternetGenTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Generator.Types.InternetGen

  describe "generate/2 with url subtype" do
    test "generates the correct number of values" do
      result = InternetGen.generate(%{"subtype" => "url"}, 10)
      assert length(result) == 10
    end

    test "generates URLs starting with http" do
      result = InternetGen.generate(%{"subtype" => "url"}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert String.starts_with?(val, "http")
      end)
    end
  end

  describe "generate/2 with ip_address subtype" do
    test "generates strings matching IP pattern" do
      result = InternetGen.generate(%{"subtype" => "ip_address"}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        # IPv4 pattern: x.x.x.x
        assert Regex.match?(~r/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/, val)
      end)
    end
  end

  describe "generate/2 with domain subtype" do
    test "generates strings containing a dot" do
      result = InternetGen.generate(%{"subtype" => "domain"}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert String.contains?(val, ".")
      end)
    end
  end

  describe "generate/2 with unknown subtype" do
    test "raises for unknown subtype" do
      assert_raise RuntimeError, ~r/Unknown internet subtype/, fn ->
        InternetGen.generate(%{"subtype" => "invalid"}, 1)
      end
    end
  end
end
