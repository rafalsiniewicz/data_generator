defmodule DataGenerator.Templates.Template do
  @moduledoc """
  Schema for data generation templates. A template defines a dataset
  structure with a name, row count, and a collection of columns.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "templates" do
    field :name, :string
    field :number_of_rows, :integer
    field :description, :string

    belongs_to :user, DataGenerator.Accounts.User
    belongs_to :project, DataGenerator.Projects.Project
    has_many :columns, DataGenerator.Templates.Column, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(template, attrs) do
    template
    |> cast(attrs, [:name, :number_of_rows, :description, :project_id])
    |> validate_required([:name, :number_of_rows])
    |> validate_number(:number_of_rows, greater_than: 0)
    |> validate_length(:name, max: 255)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:project_id)
    |> unique_constraint([:user_id, :name])
    |> cast_assoc(:columns, with: &DataGenerator.Templates.Column.changeset/2)
  end
end
