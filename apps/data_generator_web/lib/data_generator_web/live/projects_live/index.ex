defmodule DataGeneratorWeb.ProjectsLive.Index do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Projects

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    projects = Projects.list_user_projects(user.id)

    {:ok,
     socket
     |> assign(page_title: "Projects")
     |> stream(:projects, projects)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold text-gray-900">Projects</h1>
            <p class="mt-1 text-sm text-gray-600">
              Organize templates and collaborate with team members.
            </p>
          </div>
          <.link
            navigate={~p"/projects/new"}
            class="inline-flex items-center gap-1.5 rounded-lg bg-blue-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-600 transition"
          >
            <.icon name="hero-plus" class="w-4 h-4" /> New Project
          </.link>
        </div>

        <div
          id="projects"
          phx-update="stream"
          class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3"
        >
          <div
            id="projects-empty"
            class="hidden only:block col-span-full rounded-xl border border-dashed border-gray-300 bg-gray-50 p-12 text-center"
          >
            <.icon name="hero-folder" class="mx-auto w-12 h-12 text-gray-400" />
            <h3 class="mt-4 text-sm font-semibold text-gray-900">No projects yet</h3>
            <p class="mt-1 text-sm text-gray-500">Create a project to organize your templates.</p>
            <.link
              navigate={~p"/projects/new"}
              class="mt-4 inline-flex items-center gap-1.5 text-sm font-semibold text-blue-500 hover:text-blue-600"
            >
              <.icon name="hero-plus" class="w-4 h-4" /> Create project
            </.link>
          </div>

          <div
            :for={{id, project} <- @streams.projects}
            id={id}
            class="group rounded-xl border border-gray-200 bg-white p-5 shadow-sm hover:shadow-md hover:border-indigo-300 transition"
          >
            <div class="flex items-start justify-between">
              <div class="flex items-center gap-3">
                <div class="flex items-center justify-center w-10 h-10 rounded-lg bg-indigo-50 group-hover:bg-indigo-100 transition">
                  <.icon name="hero-folder" class="w-5 h-5 text-indigo-500" />
                </div>
                <div>
                  <h3 class="text-sm font-semibold text-gray-900">{project.name}</h3>
                  <p class="text-xs text-gray-500">
                    {length(project.project_members)} member(s)
                  </p>
                </div>
              </div>
            </div>
            <div class="mt-3 flex items-center gap-2">
              <div class="flex -space-x-2">
                <%= for member <- Elixir.Enum.take(project.project_members, 3) do %>
                  <div class="flex items-center justify-center w-6 h-6 rounded-full bg-gray-200 border-2 border-white text-xs font-medium text-gray-600">
                    {String.first(member.user.login)}
                  </div>
                <% end %>
                <%= if length(project.project_members) > 3 do %>
                  <div class="flex items-center justify-center w-6 h-6 rounded-full bg-gray-100 border-2 border-white text-xs font-medium text-gray-500">
                    +{length(project.project_members) - 3}
                  </div>
                <% end %>
              </div>
            </div>
            <div class="mt-3 pt-3 border-t border-gray-100 flex items-center justify-between">
              <span class="text-xs text-gray-400">
                Created {Calendar.strftime(project.inserted_at, "%b %d, %Y")}
              </span>
              <.link
                navigate={~p"/projects/#{project.id}"}
                class="text-xs font-semibold text-indigo-500 hover:text-indigo-600 transition"
              >
                View details
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
