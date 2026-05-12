defmodule DataGenerator.Generator do
  @moduledoc """
  The Generator context. Provides access to generator types and
  delegates data generation to the Engine.
  """

  alias DataGenerator.Repo
  alias DataGenerator.Generator.Type
  alias DataGenerator.Generator.Engine

  @doc """
  Lists all available generator types.
  """
  def list_types do
    Repo.all(Type)
  end

  @doc """
  Gets a single type by ID. Raises if not found.
  """
  def get_type!(id), do: Repo.get!(Type, id)

  @doc """
  Gets a single type by name. Raises if not found.
  """
  def get_type_by_name!(name), do: Repo.get_by!(Type, name: name)

  @doc """
  Generates data for the given columns and row count.
  Delegates to the Engine module.
  """
  def generate_data(columns, row_count) do
    Engine.generate(columns, row_count)
  end
end
