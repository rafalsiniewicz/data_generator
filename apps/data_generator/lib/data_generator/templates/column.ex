defmodule DataGenerator.Templates.Column do
  @moduledoc """
  Schema for template columns. Each column defines a field in the generated
  dataset, including its generator type, optional enum source, and configuration.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "columns" do
    field :name, :string
    field :config, :map
    field :description, :string

    belongs_to :type, DataGenerator.Generator.Type
    belongs_to :enum, DataGenerator.Enums.Enum
    belongs_to :template, DataGenerator.Templates.Template

    timestamps()
  end

  @doc false
  def changeset(column, attrs) do
    column
    |> cast(attrs, [:name, :type_id, :config, :enum_id, :description])
    |> validate_required([:name, :type_id, :config])
    |> foreign_key_constraint(:type_id)
    |> foreign_key_constraint(:enum_id)
    |> foreign_key_constraint(:template_id)
    |> unique_constraint([:template_id, :name])
  end
end
