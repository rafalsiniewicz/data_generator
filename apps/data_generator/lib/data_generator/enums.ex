defmodule DataGenerator.Enums do
  @moduledoc """
  The Enums context. Manages user-defined enumerations and their values.
  """

  import Ecto.Query

  alias DataGenerator.Repo
  alias DataGenerator.Enums.Enum, as: UserEnum

  @doc """
  Lists all enums for a given user, with their values preloaded.
  Optionally filters by search term matching enum name.
  """
  def list_user_enums(user_id, opts \\ []) do
    search = Keyword.get(opts, :search, nil)

    from(e in UserEnum,
      where: e.user_id == ^user_id,
      preload: [:enum_values],
      order_by: [asc: e.name]
    )
    |> maybe_search(search)
    |> Repo.all()
  end

  defp maybe_search(query, nil), do: query
  defp maybe_search(query, ""), do: query

  defp maybe_search(query, search) do
    term = "%#{search}%"
    where(query, [e], ilike(e.name, ^term))
  end

  @doc """
  Gets a single enum by ID with enum_values preloaded. Raises if not found.
  """
  def get_enum!(id) do
    UserEnum
    |> Repo.get!(id)
    |> Repo.preload(:enum_values)
  end

  @doc """
  Gets a single enum by ID, scoped to a specific user. Raises if not found
  or if the enum doesn't belong to the user.
  """
  def get_user_enum!(user_id, id) do
    UserEnum
    |> where([e], e.id == ^id and e.user_id == ^user_id)
    |> Repo.one!()
    |> Repo.preload(:enum_values)
  end

  @doc """
  Creates an enum for the given user with nested enum_values.
  The user_id is set programmatically and cannot be overridden by attrs.
  """
  def create_enum(user_id, attrs) do
    %UserEnum{user_id: user_id}
    |> UserEnum.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an enum and its nested enum_values via cast_assoc.
  """
  def update_enum(%UserEnum{} = enum, attrs) do
    enum
    |> UserEnum.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an enum. Enum values are cascade-deleted by the database.
  """
  def delete_enum(%UserEnum{} = enum) do
    Repo.delete(enum)
  end

  @doc """
  Returns a changeset for tracking enum changes.
  """
  def change_enum(%UserEnum{} = enum, attrs \\ %{}) do
    UserEnum.changeset(enum, attrs)
  end

  @doc """
  Returns the count of enums owned by a user.
  """
  def count_user_enums(user_id) do
    from(e in UserEnum,
      where: e.user_id == ^user_id,
      select: count(e.id)
    )
    |> Repo.one()
  end

  @doc """
  Returns a composable query for user enum details.
  """
  def enum_details_query(user_id) do
    from e in UserEnum,
      where: e.user_id == ^user_id,
      left_join: ev in assoc(e, :enum_values),
      preload: [enum_values: ev],
      order_by: [asc: e.name]
  end
end
