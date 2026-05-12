defmodule DataGenerator.Generator.Types.UUIDGen do
  @moduledoc """
  Generates random UUID v4 values.
  """

  @doc """
  Generates `count` random UUIDs.

  No configuration options needed.
  """
  def generate(_config, count) do
    Enum.map(1..count, fn _ -> Ecto.UUID.generate() end)
  end
end
