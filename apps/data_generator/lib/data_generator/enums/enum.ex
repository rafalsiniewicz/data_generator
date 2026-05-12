defmodule DataGenerator.Enums.Enum do
  @moduledoc """
  Schema for user-defined enumerations used as custom data sources
  in template columns. Each enum has a set of possible values.

  Note: This module intentionally shadows `Elixir.Enum`. Use the fully
  qualified `Elixir.Enum` when standard enum functions are needed within
  modules that alias this schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "enums" do
    field :name, :string

    belongs_to :user, DataGenerator.Accounts.User
    has_many :enum_values, DataGenerator.Enums.EnumValue, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(enum, attrs) do
    enum
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :name])
    |> cast_assoc(:enum_values, with: &DataGenerator.Enums.EnumValue.changeset/2)
    |> validate_at_least_one_value()
  end

  defp validate_at_least_one_value(changeset) do
    case get_field(changeset, :enum_values) do
      [] -> add_error(changeset, :enum_values, "must have at least one value")
      nil -> add_error(changeset, :enum_values, "must have at least one value")
      _ -> changeset
    end
  end
end
