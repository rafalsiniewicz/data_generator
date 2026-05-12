defmodule DataGenerator.Projects.ProjectMember do
  @moduledoc """
  Schema for the join table between projects and users.
  Tracks project membership and ownership.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "project_members" do
    field :is_owner, :boolean, default: false

    belongs_to :project, DataGenerator.Projects.Project
    belongs_to :user, DataGenerator.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(project_member, attrs) do
    project_member
    |> cast(attrs, [:project_id, :user_id, :is_owner])
    |> validate_required([:project_id, :user_id])
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:project_id, :user_id])
  end
end
