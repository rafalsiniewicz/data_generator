defmodule DataGeneratorWeb.ProjectsLiveTest do
  use DataGeneratorWeb.ConnCase, async: true

  alias DataGenerator.Projects

  # ── Helpers ───────────────────────────────────────────────────

  defp create_user(_context) do
    user = insert(:user)
    %{user: user}
  end

  defp create_project(%{user: user}) do
    {:ok, project} = Projects.create_project(user.id, %{"name" => "Test Project"})
    %{project: project}
  end

  defp authenticate(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end

  # ── Authentication Required ──────────────────────────────────

  describe "authentication" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/projects")
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/projects/new")
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/projects/1")
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/projects/1/members")
    end
  end

  # ── Index ────────────────────────────────────────────────────

  describe "Index" do
    setup [:create_user, :authenticate, :create_project]

    test "lists user's projects", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")

      assert has_element?(view, "h1", "Projects")
      assert has_element?(view, "h3", "Test Project")
    end

    test "shows member count", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")
      assert has_element?(view, "p", "1 member(s)")
    end

    test "shows empty state when no projects", %{conn: conn} do
      # Create a new user with no projects
      user2 = insert(:user)
      conn2 = log_in_user(build_conn(), user2)
      {:ok, view, _html} = live(conn2, ~p"/projects")

      assert has_element?(view, "h3", "No projects yet")
    end

    test "New Project link navigates correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")

      assert has_element?(view, "a", "New Project")
    end
  end

  # ── New ──────────────────────────────────────────────────────

  describe "New" do
    setup [:create_user, :authenticate]

    test "renders new project form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      assert has_element?(view, "h1", "New Project")
      assert has_element?(view, "#project-form")
    end

    test "creates project and redirects to show", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      view
      |> form("#project-form", project: %{name: "Brand New Project"})
      |> render_submit()

      flash = assert_redirect(view)
      assert flash["info"] =~ "Project created successfully"
    end

    test "validates blank name", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      html =
        view
        |> form("#project-form", project: %{name: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank" or html =~ "can't be blank"
    end

    test "user becomes owner after creation", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      view
      |> form("#project-form", project: %{name: "Ownership Test"})
      |> render_submit()

      projects = Projects.list_user_projects(user.id)
      project = Enum.find(projects, fn p -> p.name == "Ownership Test" end)
      assert project

      members =
        Projects.get_project_with_members!(project.id).project_members

      owner = Enum.find(members, fn m -> m.user_id == user.id end)
      assert owner.is_owner == true
    end
  end

  # ── Show ─────────────────────────────────────────────────────

  describe "Show" do
    setup [:create_user, :authenticate, :create_project]

    test "renders project details", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}")

      assert has_element?(view, "h1", "Test Project")
    end

    test "shows owner in members list", %{conn: conn, project: project, user: user} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}")

      assert has_element?(view, "#members")
      assert has_element?(view, "p", user.login)
      assert has_element?(view, "span", "Owner")
    end

    test "shows Manage Members link for owner", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}")

      assert has_element?(view, "a", "Manage Members")
    end

    test "does not show Manage Members for non-owner member", %{conn: conn, project: project} do
      other_user = insert(:user)
      {:ok, _} = Projects.add_member(project.id, other_user.id)

      conn2 = log_in_user(build_conn(), other_user)
      {:ok, view, _html} = live(conn2, ~p"/projects/#{project.id}")

      refute has_element?(view, "a", "Manage Members")
    end

    test "non-member is redirected", %{project: project} do
      non_member = insert(:user)
      conn2 = log_in_user(build_conn(), non_member)

      assert {:error, {:live_redirect, %{to: "/projects"}}} =
               live(conn2, ~p"/projects/#{project.id}")
    end

    test "shows templates assigned to project", %{conn: conn, project: project, user: user} do
      template = insert(:template, user: user, project: project, name: "My Template")
      # Need to add columns to avoid length error
      _template = template |> with_columns([{"col1", insert(:type)}])

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}")

      assert has_element?(view, "p", "My Template")
    end

    test "shows empty state when no templates", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}")

      assert has_element?(view, "#project-templates")
    end
  end

  # ── Members ──────────────────────────────────────────────────

  describe "Members" do
    setup [:create_user, :authenticate, :create_project]

    test "renders members page for owner", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/members")

      assert has_element?(view, "h1", "Manage Members")
      assert has_element?(view, "#add-member-form")
    end

    test "non-owner is redirected", %{project: project} do
      other_user = insert(:user)
      {:ok, _} = Projects.add_member(project.id, other_user.id)

      conn2 = log_in_user(build_conn(), other_user)

      assert {:error, {:live_redirect, %{to: path}}} =
               live(conn2, ~p"/projects/#{project.id}/members")

      assert path =~ "/projects/#{project.id}"
    end

    test "add member by email", %{conn: conn, project: project} do
      other_user = insert(:user)

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/members")

      view
      |> form("#add-member-form", member: %{email: other_user.email})
      |> render_submit()

      # The member should appear in the stream
      html = render(view)
      assert html =~ other_user.login
    end

    test "add member with non-existent email shows error", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/members")

      view
      |> form("#add-member-form", member: %{email: "nobody@example.com"})
      |> render_submit()

      assert has_element?(view, "#flash-error", "No user found")
    end

    test "add already-existing member shows error", %{conn: conn, project: project} do
      other_user = insert(:user)
      {:ok, _} = Projects.add_member(project.id, other_user.id)

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/members")

      view
      |> form("#add-member-form", member: %{email: other_user.email})
      |> render_submit()

      assert has_element?(view, "#flash-error", "Could not add member")
    end

    test "remove member", %{conn: conn, project: project} do
      other_user = insert(:user)
      {:ok, _} = Projects.add_member(project.id, other_user.id)

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/members")

      # The remove button should exist for the non-owner member
      view
      |> element("button[phx-click=remove_member][phx-value-user-id=#{other_user.id}]")
      |> render_click()

      assert has_element?(view, "#flash-info", "Member removed")
    end

    test "shows owner badge", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/members")

      assert has_element?(view, "span", "Owner")
    end
  end
end
