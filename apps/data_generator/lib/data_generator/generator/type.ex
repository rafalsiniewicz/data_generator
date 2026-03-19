defmodule DataGenerator.Generator.Type do
  @moduledoc """
  Schema for generator types (e.g. "first_name", "email", "integer").
  Each type represents a data generation strategy available in the system.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "types" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(type, attrs) do
    type
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
