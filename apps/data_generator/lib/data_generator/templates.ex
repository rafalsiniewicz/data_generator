defmodule DataGenerator.Templates do
  @moduledoc """
  The Templates context. Manages data generation templates and their columns.
  """

  import Ecto.Query

  alias DataGenerator.Repo
  alias DataGenerator.Templates.Template
  alias DataGenerator.Templates.Column

  @doc """
  Lists all templates for a given user, with columns and their types preloaded.
  Optionally filters by search term matching template name.
  """
  def list_user_templates(user_id, opts \\ []) do
    search = Keyword.get(opts, :search, nil)

    from(t in Template,
      where: t.user_id == ^user_id,
      preload: [columns: [:type]],
      order_by: [desc: t.inserted_at]
    )
    |> maybe_search(search)
    |> Repo.all()
  end

  defp maybe_search(query, nil), do: query
  defp maybe_search(query, ""), do: query

  defp maybe_search(query, search) do
    term = "%#{search}%"
    where(query, [t], ilike(t.name, ^term))
  end

  @doc """
  Gets a single template by ID. Raises if not found.
  """
  def get_template!(id), do: Repo.get!(Template, id)

  @doc """
  Gets a single template by ID, scoped to a specific user. Raises if not found
  or if the template doesn't belong to the user.
  """
  def get_user_template!(user_id, id) do
    Template
    |> where([t], t.id == ^id and t.user_id == ^user_id)
    |> Repo.one!()
    |> Repo.preload(columns: [:type])
  end

  @doc """
  Gets a single template with columns and their types preloaded.
  """
  def get_template_with_columns!(id) do
    Template
    |> Repo.get!(id)
    |> Repo.preload(columns: [:type])
  end

  @doc """
  Creates a template for the given user with nested columns.
  """
  def create_template(user_id, attrs) do
    %Template{user_id: user_id}
    |> Template.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a template and its nested columns via cast_assoc.
  """
  def update_template(%Template{} = template, attrs) do
    template
    |> Repo.preload(:columns)
    |> Template.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a template. Columns are removed via database cascade.
  """
  def delete_template(%Template{} = template) do
    Repo.delete(template)
  end

  @doc """
  Returns a changeset for tracking template changes.
  """
  def change_template(%Template{} = template, attrs \\ %{}) do
    Template.changeset(template, attrs)
  end

  @doc """
  Returns a composable query for user template details.
  """
  def template_details_query(user_id) do
    from t in Template,
      where: t.user_id == ^user_id,
      left_join: c in assoc(t, :columns),
      left_join: type in assoc(c, :type),
      preload: [columns: {c, type: type}],
      order_by: [desc: t.inserted_at]
  end

  @doc """
  Returns the count of templates owned by a user.
  """
  def count_user_templates(user_id) do
    from(t in Template,
      where: t.user_id == ^user_id,
      select: count(t.id)
    )
    |> Repo.one()
  end

  @doc """
  Returns a composable query for a template's columns.
  """
  def template_columns_query(template_id) do
    from c in Column,
      where: c.template_id == ^template_id,
      left_join: type in assoc(c, :type),
      preload: [type: type],
      order_by: [asc: c.id]
  end
end
