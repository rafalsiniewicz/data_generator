defmodule DataGenerator.ProjectsTest do
  use DataGenerator.DataCase, async: true

  alias DataGenerator.Projects
  alias DataGenerator.Projects.Project
  alias DataGenerator.Projects.ProjectMember

  # ── Helpers ───────────────────────────────────────────────────

  defp create_user(_context) do
    user = insert(:user)
    %{user: user}
  end

  defp create_project(%{user: user}) do
    {:ok, project} = Projects.create_project(user.id, %{"name" => "Test Project"})
    %{project: project}
  end

  # ── create_project/2 ─────────────────────────────────────────

  describe "create_project/2" do
    setup [:create_user]

    test "creates project and adds user as owner", %{user: user} do
      assert {:ok, %Project{} = project} =
               Projects.create_project(user.id, %{"name" => "My Project"})

      assert project.name == "My Project"

      # User should be a member and owner
      proj = Projects.get_project_with_members!(project.id)
      assert length(proj.project_members) == 1
      [member] = proj.project_members
      assert member.user_id == user.id
      assert member.is_owner == true
    end

    test "fails with blank name", %{user: user} do
      assert {:error, changeset} = Projects.create_project(user.id, %{"name" => ""})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "fails with name exceeding 100 chars", %{user: user} do
      long_name = String.duplicate("a", 101)
      assert {:error, changeset} = Projects.create_project(user.id, %{"name" => long_name})
      assert %{name: [msg]} = errors_on(changeset)
      assert msg =~ "should be at most 100 character"
    end
  end

  # ── get_project!/1 ───────────────────────────────────────────

  describe "get_project!/1" do
    setup [:create_user, :create_project]

    test "returns the project", %{project: project} do
      fetched = Projects.get_project!(project.id)
      assert fetched.id == project.id
      assert fetched.name == project.name
    end

    test "raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Projects.get_project!(0)
      end
    end
  end

  # ── get_project_with_members!/1 ──────────────────────────────

  describe "get_project_with_members!/1" do
    setup [:create_user, :create_project]

    test "returns project with preloaded members and users", %{project: project, user: user} do
      proj = Projects.get_project_with_members!(project.id)
      assert proj.id == project.id
      assert length(proj.project_members) == 1
      [member] = proj.project_members
      assert member.user.id == user.id
    end
  end

  # ── list_user_projects/1 ─────────────────────────────────────

  describe "list_user_projects/1" do
    setup [:create_user]

    test "returns projects the user is a member of", %{user: user} do
      {:ok, _p1} = Projects.create_project(user.id, %{"name" => "Project A"})
      {:ok, _p2} = Projects.create_project(user.id, %{"name" => "Project B"})

      projects = Projects.list_user_projects(user.id)
      assert length(projects) == 2
      names = Enum.map(projects, & &1.name)
      assert "Project A" in names
      assert "Project B" in names
    end

    test "does not return projects user is not a member of", %{user: user} do
      other_user = insert(:user)
      {:ok, _} = Projects.create_project(other_user.id, %{"name" => "Other Project"})

      projects = Projects.list_user_projects(user.id)
      assert projects == []
    end

    test "returns empty list for user with no projects", %{user: user} do
      assert Projects.list_user_projects(user.id) == []
    end
  end

  # ── member?/2 ────────────────────────────────────────────────

  describe "member?/2" do
    setup [:create_user, :create_project]

    test "returns true when user is a member", %{project: project, user: user} do
      assert Projects.member?(project.id, user.id) == true
    end

    test "returns false when user is not a member", %{project: project} do
      other = insert(:user)
      assert Projects.member?(project.id, other.id) == false
    end
  end

  # ── add_member/2 ─────────────────────────────────────────────

  describe "add_member/2" do
    setup [:create_user, :create_project]

    test "adds a user as member", %{project: project} do
      other = insert(:user)
      assert {:ok, %ProjectMember{} = pm} = Projects.add_member(project.id, other.id)
      assert pm.project_id == project.id
      assert pm.user_id == other.id
      assert pm.is_owner == false
    end

    test "cannot add duplicate membership", %{project: project} do
      other = insert(:user)
      assert {:ok, _} = Projects.add_member(project.id, other.id)
      assert {:error, _changeset} = Projects.add_member(project.id, other.id)
    end
  end

  # ── remove_member/2 ──────────────────────────────────────────

  describe "remove_member/2" do
    setup [:create_user, :create_project]

    test "removes a regular member", %{project: project} do
      other = insert(:user)
      {:ok, _} = Projects.add_member(project.id, other.id)

      assert {:ok, %ProjectMember{}} = Projects.remove_member(project.id, other.id)
      assert Projects.member?(project.id, other.id) == false
    end

    test "cannot remove the owner", %{project: project, user: user} do
      assert {:error, :cannot_remove_owner} = Projects.remove_member(project.id, user.id)
    end

    test "returns error for non-existent membership", %{project: project} do
      other = insert(:user)
      assert {:error, :not_found} = Projects.remove_member(project.id, other.id)
    end
  end

  # ── transfer_ownership/2 ─────────────────────────────────────

  describe "transfer_ownership/2" do
    setup [:create_user, :create_project]

    test "transfers ownership to another member", %{project: project, user: original_owner} do
      new_owner = insert(:user)
      {:ok, _} = Projects.add_member(project.id, new_owner.id)

      assert {:ok, :ok} = Projects.transfer_ownership(project.id, new_owner.id)

      proj = Projects.get_project_with_members!(project.id)

      original_member =
        Enum.find(proj.project_members, fn pm -> pm.user_id == original_owner.id end)

      new_member = Enum.find(proj.project_members, fn pm -> pm.user_id == new_owner.id end)

      assert original_member.is_owner == false
      assert new_member.is_owner == true
    end

    test "fails when target is not a member", %{project: project} do
      non_member = insert(:user)
      assert {:error, :not_found} = Projects.transfer_ownership(project.id, non_member.id)
    end
  end

  # ── assign_template_to_project/2 ─────────────────────────────

  describe "assign_template_to_project/2" do
    setup [:create_user, :create_project]

    test "assigns a template to the project", %{project: project, user: user} do
      template = insert(:template, user: user)

      assert {:ok, updated} = Projects.assign_template_to_project(template.id, project.id)
      assert updated.project_id == project.id
    end
  end

  # ── remove_template_from_project/1 ───────────────────────────

  describe "remove_template_from_project/1" do
    setup [:create_user, :create_project]

    test "removes template from project", %{project: project, user: user} do
      template = insert(:template, user: user, project: project)

      assert {:ok, updated} = Projects.remove_template_from_project(template.id)
      assert is_nil(updated.project_id)
    end
  end

  # ── list_project_templates/1 ─────────────────────────────────

  describe "list_project_templates/1" do
    setup [:create_user, :create_project]

    test "returns templates assigned to the project", %{project: project, user: user} do
      t1 = insert(:template, user: user, project: project, name: "Template A")
      _t2 = insert(:template, user: user, name: "Template B")

      templates = Projects.list_project_templates(project.id)
      assert length(templates) == 1
      assert hd(templates).id == t1.id
    end

    test "returns empty list when no templates assigned", %{project: project} do
      assert Projects.list_project_templates(project.id) == []
    end
  end

  # ── count_user_projects/1 ────────────────────────────────────

  describe "count_user_projects/1" do
    setup [:create_user]

    test "returns 0 for user with no projects", %{user: user} do
      assert Projects.count_user_projects(user.id) == 0
    end

    test "returns correct count", %{user: user} do
      {:ok, _} = Projects.create_project(user.id, %{"name" => "P1"})
      {:ok, _} = Projects.create_project(user.id, %{"name" => "P2"})
      {:ok, _} = Projects.create_project(user.id, %{"name" => "P3"})

      assert Projects.count_user_projects(user.id) == 3
    end
  end

  # ── update_project/2 ─────────────────────────────────────────

  describe "update_project/2" do
    setup [:create_user, :create_project]

    test "updates the project name", %{project: project} do
      assert {:ok, updated} = Projects.update_project(project, %{"name" => "Renamed"})
      assert updated.name == "Renamed"
    end

    test "fails with blank name", %{project: project} do
      assert {:error, changeset} = Projects.update_project(project, %{"name" => ""})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  # ── delete_project/1 ─────────────────────────────────────────

  describe "delete_project/1" do
    setup [:create_user, :create_project]

    test "deletes the project", %{project: project} do
      assert {:ok, %Project{}} = Projects.delete_project(project)

      assert_raise Ecto.NoResultsError, fn ->
        Projects.get_project!(project.id)
      end
    end
  end

  # ── change_project/2 ─────────────────────────────────────────

  describe "change_project/2" do
    test "returns a changeset" do
      changeset = Projects.change_project(%Project{})
      assert %Ecto.Changeset{} = changeset
    end
  end
end
