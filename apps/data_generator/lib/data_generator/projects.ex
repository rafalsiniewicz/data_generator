defmodule DataGenerator.Projects do
  @moduledoc """
  The Projects context. Manages projects, membership, and template assignment.
  """

  import Ecto.Query

  alias DataGenerator.Repo
  alias DataGenerator.Projects.Project
  alias DataGenerator.Projects.ProjectMember
  alias DataGenerator.Templates.Template

  @doc """
  Lists all projects where the given user is a member, including role info.
  """
  def list_user_projects(user_id) do
    from(p in Project,
      join: pm in ProjectMember,
      on: pm.project_id == p.id and pm.user_id == ^user_id,
      preload: [project_members: [:user]],
      order_by: [desc: p.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single project by ID. Raises if not found.
  """
  def get_project!(id), do: Repo.get!(Project, id)

  @doc """
  Gets a single project with members and their user data preloaded.
  """
  def get_project_with_members!(id) do
    Project
    |> Repo.get!(id)
    |> Repo.preload(project_members: [:user])
  end

  @doc """
  Creates a project and adds the creating user as the owner.
  Uses Ecto.Multi to ensure atomicity.
  """
  def create_project(user_id, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:project, Project.changeset(%Project{}, attrs))
    |> Ecto.Multi.insert(:project_member, fn %{project: project} ->
      ProjectMember.changeset(%ProjectMember{}, %{
        project_id: project.id,
        user_id: user_id,
        is_owner: true
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{project: project}} -> {:ok, project}
      {:error, _step, changeset, _changes} -> {:error, changeset}
    end
  end

  @doc """
  Adds a user as a member to a project.
  """
  def add_member(project_id, user_id) do
    %ProjectMember{}
    |> ProjectMember.changeset(%{project_id: project_id, user_id: user_id})
    |> Repo.insert()
  end

  @doc """
  Removes a member from a project. Cannot remove the owner.
  """
  def remove_member(project_id, user_id) do
    case Repo.one(
           from pm in ProjectMember,
             where: pm.project_id == ^project_id and pm.user_id == ^user_id
         ) do
      nil ->
        {:error, :not_found}

      %ProjectMember{is_owner: true} ->
        {:error, :cannot_remove_owner}

      member ->
        Repo.delete(member)
    end
  end

  @doc """
  Transfers project ownership from the current owner to the specified member.

  Removes ownership from the current owner and grants it to the new owner,
  within a transaction to ensure atomicity.
  """
  def transfer_ownership(project_id, new_owner_user_id) do
    Repo.transaction(fn ->
      # Verify the target user is a member of the project
      case Repo.one(
             from pm in ProjectMember,
               where: pm.project_id == ^project_id and pm.user_id == ^new_owner_user_id
           ) do
        nil ->
          Repo.rollback(:not_found)

        _member ->
          # Remove is_owner from current owner
          from(pm in ProjectMember,
            where: pm.project_id == ^project_id and pm.is_owner == true
          )
          |> Repo.update_all(set: [is_owner: false])

          # Set new owner
          from(pm in ProjectMember,
            where: pm.project_id == ^project_id and pm.user_id == ^new_owner_user_id
          )
          |> Repo.update_all(set: [is_owner: true])

          :ok
      end
    end)
  end

  @doc """
  Assigns a template to a project by setting the template's project_id.
  """
  def assign_template_to_project(template_id, project_id) do
    template = Repo.get!(Template, template_id)

    template
    |> Ecto.Changeset.change(%{project_id: project_id})
    |> Repo.update()
  end

  @doc """
  Removes a template from a project by setting project_id to nil.
  """
  def remove_template_from_project(template_id) do
    template = Repo.get!(Template, template_id)

    template
    |> Ecto.Changeset.change(%{project_id: nil})
    |> Repo.update()
  end

  @doc """
  Returns a changeset for tracking project changes.
  """
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  @doc """
  Updates a project.
  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project.
  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Checks if a user is a member of a project.
  """
  def member?(project_id, user_id) do
    query =
      from pm in ProjectMember,
        where: pm.project_id == ^project_id and pm.user_id == ^user_id

    Repo.exists?(query)
  end

  @doc """
  Lists all templates belonging to a project, with columns preloaded.
  """
  def list_project_templates(project_id) do
    from(t in Template,
      where: t.project_id == ^project_id,
      preload: [:columns],
      order_by: [desc: t.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Returns the count of projects a user is a member of.
  """
  def count_user_projects(user_id) do
    from(pm in ProjectMember,
      where: pm.user_id == ^user_id,
      select: count(pm.id)
    )
    |> Repo.one()
  end

  @doc """
  Returns a composable query for a user's projects.
  """
  def user_projects_query(user_id) do
    from p in Project,
      join: pm in ProjectMember,
      on: pm.project_id == p.id and pm.user_id == ^user_id,
      order_by: [desc: p.inserted_at]
  end
end
