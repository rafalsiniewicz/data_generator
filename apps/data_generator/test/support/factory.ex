defmodule DataGenerator.Factory do
  @moduledoc """
  ExMachina factory definitions for test data.
  """

  use ExMachina.Ecto, repo: DataGenerator.Repo

  alias DataGenerator.Accounts.User
  alias DataGenerator.Enums.Enum, as: UserEnum
  alias DataGenerator.Enums.EnumValue
  alias DataGenerator.Templates.Template
  alias DataGenerator.Templates.Column
  alias DataGenerator.Generator.Type
  alias DataGenerator.Projects.Project
  alias DataGenerator.Projects.ProjectMember

  # ── User ──────────────────────────────────────────────────────

  def user_factory do
    %User{
      email: sequence(:email, &"user#{&1}@example.com"),
      login: sequence(:login, &"user#{&1}"),
      password_hash: Bcrypt.hash_pwd_salt("Password123!")
    }
  end

  # ── Type ──────────────────────────────────────────────────────

  def type_factory do
    %Type{
      name: sequence(:type_name, &"type_#{&1}")
    }
  end

  # ── Enum (aliased as enum_definition to avoid Elixir.Enum conflict) ──

  def enum_definition_factory do
    %UserEnum{
      name: sequence(:enum_name, &"enum_#{&1}"),
      user: build(:user)
    }
  end

  def enum_value_factory do
    %EnumValue{
      value: sequence(:enum_value, &"value_#{&1}")
    }
  end

  @doc """
  Convenience: builds an enum with N values already associated.

  ## Examples

      insert(:enum_definition) |> with_values(["red", "green", "blue"])
  """
  def with_values(enum, values) when is_list(values) do
    enum_values =
      Enum.map(values, fn v ->
        insert(:enum_value, value: v, enum_id: enum.id)
      end)

    %{enum | enum_values: enum_values}
  end

  # ── Template ──────────────────────────────────────────────────

  def template_factory do
    %Template{
      name: sequence(:template_name, &"template_#{&1}"),
      number_of_rows: 100,
      description: "A test template",
      user: build(:user)
    }
  end

  # ── Column ────────────────────────────────────────────────────

  def column_factory do
    %Column{
      name: sequence(:column_name, &"column_#{&1}"),
      config: %{},
      type: build(:type),
      template: build(:template)
    }
  end

  @doc """
  Convenience: inserts a template with N columns already associated.
  Each column gets a type record.

  ## Examples

      insert(:template) |> with_columns([{"first_name", type}, {"age", type2}])
  """
  def with_columns(template, column_defs) when is_list(column_defs) do
    columns =
      Enum.map(column_defs, fn
        {name, type} ->
          insert(:column, name: name, type: type, template: template, template_id: template.id)

        {name, type, config} ->
          insert(:column,
            name: name,
            type: type,
            config: config,
            template: template,
            template_id: template.id
          )
      end)

    %{template | columns: columns}
  end

  # ── Project ───────────────────────────────────────────────────

  def project_factory do
    %Project{
      name: sequence(:project_name, &"project_#{&1}")
    }
  end

  # ── ProjectMember ─────────────────────────────────────────────

  def project_member_factory do
    %ProjectMember{
      is_owner: false,
      project: build(:project),
      user: build(:user)
    }
  end

  # ── Helpers ──────────────────────────────────────────────────

  @doc """
  Marks a user's email as confirmed by inserting a confirmed verification token.
  """
  def confirm_user_email(%User{} = user) do
    alias DataGenerator.Accounts.EmailVerificationToken

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %EmailVerificationToken{}
    |> EmailVerificationToken.changeset(%{
      user_id: user.id,
      token_hash: :crypto.strong_rand_bytes(32) |> Base.encode16(case: :lower),
      context: "confirm_email",
      expires_at: DateTime.add(now, 24 * 3600, :second),
      confirmed_at: now
    })
    |> DataGenerator.Repo.insert!()

    user
  end
end
