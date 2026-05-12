defmodule DataGenerator.Enums.EnumValue do
  @moduledoc """
  Schema for individual values belonging to a user-defined enum.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "enum_values" do
    field :value, :string

    belongs_to :enum, DataGenerator.Enums.Enum

    timestamps()
  end

  @doc false
  def changeset(enum_value, attrs) do
    enum_value
    |> cast(attrs, [:value, :enum_id])
    |> validate_required([:value])
    |> validate_length(:value, max: 50)
    |> foreign_key_constraint(:enum_id)
    |> unique_constraint([:enum_id, :value])
  end
end
