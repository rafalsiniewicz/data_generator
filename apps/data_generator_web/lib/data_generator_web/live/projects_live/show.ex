defmodule DataGeneratorWeb.ProjectsLive.Show do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Projects

  def mount(%{"id" => id}, _session, socket) do
    project = Projects.get_project_with_members!(id)
    user = socket.assigns.current_user

    if not Projects.member?(project.id, user.id) do
      {:ok,
       socket
       |> put_flash(:error, "You are not a member of this project.")
       |> push_navigate(to: ~p"/projects")}
    else
      project_templates = Projects.list_project_templates(project.id)

      is_owner =
        Elixir.Enum.any?(project.project_members, fn pm ->
          pm.user_id == user.id && pm.is_owner
        end)

      {:ok,
       socket
       |> assign(
         page_title: project.name,
         project: project,
         is_owner: is_owner
       )
       |> stream(:project_templates, project_templates)
       |> stream(:members, project.project_members)}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <%!-- Header --%>
        <div class="flex items-start justify-between">
          <div>
            <.link
              navigate={~p"/projects"}
              class="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 transition mb-2"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Projects
            </.link>
            <h1 class="text-2xl font-bold text-gray-900">{@project.name}</h1>
            <p class="mt-1 text-sm text-gray-600">
              Created {Calendar.strftime(@project.inserted_at, "%B %d, %Y")}
            </p>
          </div>
          <%= if @is_owner do %>
            <.link
              navigate={~p"/projects/#{@project.id}/members"}
              class="inline-flex items-center gap-1.5 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-semibold text-gray-700 shadow-sm hover:bg-gray-50 transition"
            >
              <.icon name="hero-user-group" class="w-4 h-4" /> Manage Members
            </.link>
          <% end %>
        </div>

        <%!-- Members --%>
        <div class="rounded-xl border border-gray-200 bg-white shadow-sm">
          <div class="border-b border-gray-200 px-6 py-4">
            <h2 class="text-lg font-semibold text-gray-900">Members</h2>
          </div>
          <div id="members" phx-update="stream" class="divide-y divide-gray-100">
            <div
              :for={{id, member} <- @streams.members}
              id={id}
              class="flex items-center justify-between px-6 py-3"
            >
              <div class="flex items-center gap-3">
                <div class="flex items-center justify-center w-8 h-8 rounded-full bg-indigo-100 text-sm font-semibold text-indigo-600">
                  {String.first(member.user.login)}
                </div>
                <div>
                  <p class="text-sm font-medium text-gray-900">{member.user.login}</p>
                  <p class="text-xs text-gray-500">{member.user.email}</p>
                </div>
              </div>
              <span class={[
                "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
                if(member.is_owner,
                  do: "bg-indigo-100 text-indigo-700",
                  else: "bg-gray-100 text-gray-700"
                )
              ]}>
                <%= if member.is_owner do %>
                  Owner
                <% else %>
                  Member
                <% end %>
              </span>
            </div>
          </div>
        </div>

        <%!-- Templates --%>
        <div class="rounded-xl border border-gray-200 bg-white shadow-sm">
          <div class="flex items-center justify-between border-b border-gray-200 px-6 py-4">
            <h2 class="text-lg font-semibold text-gray-900">Templates</h2>
            <.link
              navigate={~p"/templates/new"}
              class="text-sm font-semibold text-blue-500 hover:text-blue-600 transition"
            >
              Add template
            </.link>
          </div>
          <div id="project-templates" phx-update="stream">
            <div class="hidden only:block px-6 py-12 text-center text-sm text-gray-500">
              No templates in this project yet.
            </div>
            <div
              :for={{id, template} <- @streams.project_templates}
              id={id}
              class="flex items-center justify-between border-b border-gray-100 last:border-0 px-6 py-4 hover:bg-gray-50 transition"
            >
              <div class="flex items-center gap-3">
                <.icon name="hero-document-duplicate" class="w-5 h-5 text-blue-400" />
                <div>
                  <p class="text-sm font-medium text-gray-900">{template.name}</p>
                  <p class="text-xs text-gray-500">
                    {length(template.columns)} columns &middot; {template.number_of_rows} rows
                  </p>
                </div>
              </div>
              <.link
                navigate={~p"/templates/#{template.id}/edit"}
                class="text-sm text-blue-500 hover:text-blue-600 transition"
              >
                Edit
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
