defmodule DataGenerator.Generator.PropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias DataGenerator.Generator.Types.{
    IntegerGen,
    FloatGen,
    StringGen,
    BooleanGen,
    DateGen,
    EnumGen,
    RegexGen
  }

  describe "IntegerGen property" do
    property "generated value is always within [min, max]" do
      check all(
              min <- integer(-1000..1000),
              max <- integer(-1000..1000),
              min <= max
            ) do
        config = %{"min" => min, "max" => max}
        [value] = IntegerGen.generate(config, 1)
        assert value >= min
        assert value <= max
      end
    end
  end

  describe "FloatGen property" do
    property "generated value is within [min, max] with correct precision" do
      check all(
              min <- integer(0..100),
              max <- integer(100..200),
              precision <- integer(0..6)
            ) do
        min_f = min / 1
        max_f = max / 1
        config = %{"min" => min_f, "max" => max_f, "precision" => precision}
        [value] = FloatGen.generate(config, 1)
        assert value >= min_f
        assert value <= max_f
        assert value == Float.round(value, precision)
      end
    end
  end

  describe "StringGen property" do
    property "generated string has correct length" do
      check all(length <- integer(1..100)) do
        config = %{"length" => length}
        [value] = StringGen.generate(config, 1)
        assert String.length(value) == length
      end
    end
  end

  describe "BooleanGen property" do
    property "generated value is always a boolean" do
      check all(ratio <- float(min: 0.0, max: 1.0)) do
        config = %{"true_ratio" => ratio}
        [value] = BooleanGen.generate(config, 1)
        assert is_boolean(value)
      end
    end
  end

  describe "DateGen property" do
    property "generated date is within [from, to]" do
      check all(
              year_from <- integer(2000..2020),
              year_to <- integer(2020..2030)
            ) do
        from = "#{year_from}-01-01"
        to = "#{year_to}-12-31"
        config = %{"from" => from, "to" => to}
        [value] = DateGen.generate(config, 1)
        date = Date.from_iso8601!(value)
        from_date = Date.from_iso8601!(from)
        to_date = Date.from_iso8601!(to)
        assert Date.compare(date, from_date) in [:gt, :eq]
        assert Date.compare(date, to_date) in [:lt, :eq]
      end
    end
  end

  describe "EnumGen property" do
    property "generated value is always from the provided values list" do
      check all(
              values <-
                list_of(string(:alphanumeric, min_length: 1), min_length: 1, max_length: 20)
            ) do
        config = %{"values" => values}
        [value] = EnumGen.generate(config, 1)
        assert value in values
      end
    end
  end

  describe "RegexGen property" do
    property "generated string matches simple [a-z]{n} patterns" do
      check all(n <- integer(1..20)) do
        pattern = "[a-z]{#{n}}"
        config = %{"pattern" => pattern}
        [value] = RegexGen.generate(config, 1)
        regex = Regex.compile!("^[a-z]{#{n}}$")
        assert Regex.match?(regex, value)
      end
    end
  end
end
