defmodule DataGenerator.Generator.Types.DateTimeGenTest do
  use ExUnit.Case, async: true

  alias DataGenerator.Generator.Types.DateTimeGen

  describe "generate/2" do
    test "generates the correct number of values" do
      result = DateTimeGen.generate(%{}, 10)
      assert length(result) == 10
    end

    test "generates valid ISO 8601 datetime strings" do
      result = DateTimeGen.generate(%{}, 50)

      Enum.each(result, fn val ->
        assert is_binary(val)
        assert {:ok, _dt, _offset} = DateTime.from_iso8601(val)
      end)
    end

    test "generates datetimes within default range" do
      result = DateTimeGen.generate(%{}, 100)
      {:ok, from_dt, _} = DateTime.from_iso8601("2020-01-01T00:00:00Z")
      {:ok, to_dt, _} = DateTime.from_iso8601("2025-12-31T23:59:59Z")

      Enum.each(result, fn val ->
        {:ok, dt, _} = DateTime.from_iso8601(val)
        assert DateTime.compare(dt, from_dt) in [:gt, :eq]
        assert DateTime.compare(dt, to_dt) in [:lt, :eq]
      end)
    end

    test "generates datetimes within custom range" do
      config = %{
        "from" => "2024-06-01T00:00:00Z",
        "to" => "2024-06-01T23:59:59Z"
      }

      result = DateTimeGen.generate(config, 100)
      {:ok, from_dt, _} = DateTime.from_iso8601("2024-06-01T00:00:00Z")
      {:ok, to_dt, _} = DateTime.from_iso8601("2024-06-01T23:59:59Z")

      Enum.each(result, fn val ->
        {:ok, dt, _} = DateTime.from_iso8601(val)
        assert DateTime.compare(dt, from_dt) in [:gt, :eq]
        assert DateTime.compare(dt, to_dt) in [:lt, :eq]
      end)
    end
  end
end
