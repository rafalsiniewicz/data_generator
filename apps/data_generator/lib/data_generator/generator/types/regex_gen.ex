defmodule DataGenerator.Generator.Types.RegexGen do
  @moduledoc """
  Simple regex-based string generator. Supports basic character classes,
  quantifiers, and literal characters.

  Supported patterns:
    - `[A-Z]`, `[a-z]`, `[0-9]` — character ranges
    - `[abc]` — character sets
    - `\\d` — digit (0-9)
    - `\\w` — word character (a-z, A-Z, 0-9, _)
    - `{n}` — exactly n repetitions
    - `{n,m}` — between n and m repetitions
    - `+` — 1 to 5 repetitions
    - `*` — 0 to 5 repetitions
    - `?` — 0 or 1 repetitions
    - Literal characters
  """

  @doc """
  Generates `count` strings matching the given regex pattern.

  Config options:
    - `"pattern"` — the regex pattern string (required)
  """
  def generate(config, count) do
    pattern = Map.get(config, "pattern", "[a-z]{10}")
    tokens = parse(pattern)

    Enum.map(1..count, fn _ ->
      tokens
      |> Enum.map(&generate_token/1)
      |> IO.iodata_to_binary()
    end)
  end

  # -- Parser --

  defp parse(pattern) do
    parse(String.to_charlist(pattern), [])
  end

  defp parse([], acc), do: Enum.reverse(acc)

  # Escaped character classes
  defp parse([?\\, ?d | rest], acc) do
    {quantifier, rest} = parse_quantifier(rest)
    parse(rest, [{:class, :digit, quantifier} | acc])
  end

  defp parse([?\\, ?w | rest], acc) do
    {quantifier, rest} = parse_quantifier(rest)
    parse(rest, [{:class, :word, quantifier} | acc])
  end

  # Escaped literal
  defp parse([?\\, char | rest], acc) do
    {quantifier, rest} = parse_quantifier(rest)
    parse(rest, [{:literal, char, quantifier} | acc])
  end

  # Character class [...]
  defp parse([?[ | rest], acc) do
    {chars, rest} = parse_char_class(rest, [])
    {quantifier, rest} = parse_quantifier(rest)
    parse(rest, [{:charset, chars, quantifier} | acc])
  end

  # Literal character
  defp parse([char | rest], acc) do
    {quantifier, rest} = parse_quantifier(rest)
    parse(rest, [{:literal, char, quantifier} | acc])
  end

  # -- Character class parser --

  defp parse_char_class([?] | rest], acc), do: {Enum.reverse(acc), rest}

  defp parse_char_class([from, ?-, to | rest], acc) when from <= to do
    chars = Enum.to_list(from..to)
    parse_char_class(rest, Enum.reverse(chars) ++ acc)
  end

  defp parse_char_class([char | rest], acc) do
    parse_char_class(rest, [char | acc])
  end

  defp parse_char_class([], acc), do: {Enum.reverse(acc), []}

  # -- Quantifier parser --

  defp parse_quantifier([?{ | rest]) do
    {quantifier_str, rest} = take_until_close_brace(rest, [])

    case String.split(List.to_string(quantifier_str), ",") do
      [n_str] ->
        n = String.to_integer(String.trim(n_str))
        {{:exact, n}, rest}

      [n_str, m_str] ->
        n = String.to_integer(String.trim(n_str))
        m = String.to_integer(String.trim(m_str))
        {{:range, n, m}, rest}
    end
  end

  defp parse_quantifier([?+ | rest]), do: {{:range, 1, 5}, rest}
  defp parse_quantifier([?* | rest]), do: {{:range, 0, 5}, rest}
  defp parse_quantifier([?? | rest]), do: {{:range, 0, 1}, rest}
  defp parse_quantifier(rest), do: {{:exact, 1}, rest}

  defp take_until_close_brace([?} | rest], acc), do: {Enum.reverse(acc), rest}
  defp take_until_close_brace([char | rest], acc), do: take_until_close_brace(rest, [char | acc])
  defp take_until_close_brace([], acc), do: {Enum.reverse(acc), []}

  # -- Token generator --

  defp generate_token({:literal, char, quantifier}) do
    repeat_count(quantifier)
    |> then(fn n -> List.duplicate(char, n) end)
  end

  defp generate_token({:charset, chars, quantifier}) do
    n = repeat_count(quantifier)

    Enum.map(1..max(n, 1)//1, fn _ -> Enum.random(chars) end)
    |> then(fn result -> if n == 0, do: [], else: result end)
  end

  defp generate_token({:class, :digit, quantifier}) do
    generate_token({:charset, Enum.to_list(?0..?9), quantifier})
  end

  defp generate_token({:class, :word, quantifier}) do
    chars = Enum.to_list(?a..?z) ++ Enum.to_list(?A..?Z) ++ Enum.to_list(?0..?9) ++ [?_]
    generate_token({:charset, chars, quantifier})
  end

  defp repeat_count({:exact, n}), do: n
  defp repeat_count({:range, min, max}), do: Enum.random(min..max)
end
