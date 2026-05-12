defmodule DataGenerator.Generator.Types.BooleanGenTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Generator.Types.BooleanGen

  describe "generate/2" do
    test "generates the correct number of values" do
      result = BooleanGen.generate(%{}, 10)
      assert length(result) == 10
    end

    test "generates only boolean values" do
      result = BooleanGen.generate(%{}, 100)

      Enum.each(result, fn val ->
        assert is_boolean(val)
      end)
    end

    test "ratio roughly correct over many samples with 0.0 ratio" do
      result = BooleanGen.generate(%{"true_ratio" => 0.0}, 1000)
      true_count = Enum.count(result, & &1)
      assert true_count == 0
    end

    test "ratio roughly correct over many samples with 1.0 ratio" do
      result = BooleanGen.generate(%{"true_ratio" => 1.0}, 1000)
      # With ratio 1.0, :rand.uniform() < 1.0 is almost always true
      # but :rand.uniform() returns (0, 1] so it could equal 1.0 exactly
      true_count = Enum.count(result, & &1)
      assert true_count >= 990
    end

    test "ratio roughly correct with default 0.5 ratio" do
      result = BooleanGen.generate(%{}, 10_000)
      true_count = Enum.count(result, & &1)
      # With 10k samples and 0.5 ratio, should be roughly 5000 ± 500
      assert true_count > 4000
      assert true_count < 6000
    end

    test "handles string config values" do
      result = BooleanGen.generate(%{"true_ratio" => "0.5"}, 10)

      Enum.each(result, fn val ->
        assert is_boolean(val)
      end)
    end
  end
end
