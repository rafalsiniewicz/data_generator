defmodule DataGenerator.Projects.Project do
  @moduledoc """
  Schema for projects that group templates and organize team collaboration.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string

    has_many :project_members, DataGenerator.Projects.ProjectMember
    has_many :users, through: [:project_members, :user]
    has_many :templates, DataGenerator.Templates.Template

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, max: 100)
  end
end
