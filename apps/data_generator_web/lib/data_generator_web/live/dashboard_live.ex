defmodule DataGeneratorWeb.DashboardLive do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Templates
  alias DataGenerator.Projects
  alias DataGenerator.Enums

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    templates_count = Templates.count_user_templates(user.id)
    projects_count = Projects.count_user_projects(user.id)
    enums_count = Enums.count_user_enums(user.id)

    recent_projects =
      Projects.list_user_projects(user.id)
      |> Elixir.Enum.take(5)

    {:ok,
     socket
     |> assign(
       page_title: "Dashboard",
       templates_count: templates_count,
       projects_count: projects_count,
       enums_count: enums_count
     )
     |> stream(:recent_projects, recent_projects)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <%!-- Header --%>
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold text-gray-900">Dashboard</h1>
            <p class="mt-1 text-sm text-gray-600">Welcome back, {@current_user.login}</p>
          </div>
          <.link
            navigate={~p"/generate"}
            class="rounded-lg bg-blue-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-600 transition"
          >
            <.icon name="hero-bolt" class="w-4 h-4 inline -mt-0.5 mr-1" /> Quick Generate
          </.link>
        </div>

        <%!-- Stat Cards --%>
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-3">
          <.link
            navigate={~p"/templates"}
            class="group rounded-xl border border-gray-200 bg-white p-6 shadow-sm hover:shadow-md hover:border-blue-300 transition"
          >
            <div class="flex items-center gap-4">
              <div class="flex items-center justify-center w-12 h-12 rounded-full bg-blue-50 group-hover:bg-blue-100 transition">
                <.icon name="hero-document-duplicate" class="w-6 h-6 text-blue-500" />
              </div>
              <div>
                <p class="text-sm font-medium text-gray-600">Templates</p>
                <p class="text-2xl font-bold text-gray-900">{@templates_count}</p>
              </div>
            </div>
          </.link>

          <.link
            navigate={~p"/projects"}
            class="group rounded-xl border border-gray-200 bg-white p-6 shadow-sm hover:shadow-md hover:border-blue-300 transition"
          >
            <div class="flex items-center gap-4">
              <div class="flex items-center justify-center w-12 h-12 rounded-full bg-indigo-50 group-hover:bg-indigo-100 transition">
                <.icon name="hero-folder" class="w-6 h-6 text-indigo-500" />
              </div>
              <div>
                <p class="text-sm font-medium text-gray-600">Projects</p>
                <p class="text-2xl font-bold text-gray-900">{@projects_count}</p>
              </div>
            </div>
          </.link>

          <.link
            navigate={~p"/enums"}
            class="group rounded-xl border border-gray-200 bg-white p-6 shadow-sm hover:shadow-md hover:border-blue-300 transition"
          >
            <div class="flex items-center gap-4">
              <div class="flex items-center justify-center w-12 h-12 rounded-full bg-purple-50 group-hover:bg-purple-100 transition">
                <.icon name="hero-list-bullet" class="w-6 h-6 text-purple-500" />
              </div>
              <div>
                <p class="text-sm font-medium text-gray-600">Enums</p>
                <p class="text-2xl font-bold text-gray-900">{@enums_count}</p>
              </div>
            </div>
          </.link>
        </div>

        <%!-- Recent Projects --%>
        <div class="rounded-xl border border-gray-200 bg-white shadow-sm">
          <div class="flex items-center justify-between border-b border-gray-200 px-6 py-4">
            <h2 class="text-lg font-semibold text-gray-900">Recent Projects</h2>
            <.link
              navigate={~p"/projects/new"}
              class="text-sm font-semibold text-blue-500 hover:text-blue-600 transition"
            >
              New project
            </.link>
          </div>
          <div id="recent-projects" phx-update="stream">
            <div class="hidden only:block px-6 py-12 text-center text-sm text-gray-500">
              No projects yet. Create your first project to get started.
            </div>
            <div
              :for={{id, project} <- @streams.recent_projects}
              id={id}
              class="flex items-center justify-between border-b border-gray-100 last:border-0 px-6 py-4 hover:bg-gray-50 transition"
            >
              <div class="flex items-center gap-3">
                <div class="flex items-center justify-center w-8 h-8 rounded-full bg-indigo-50">
                  <.icon name="hero-folder" class="w-4 h-4 text-indigo-500" />
                </div>
                <div>
                  <p class="text-sm font-medium text-gray-900">{project.name}</p>
                  <p class="text-xs text-gray-500">
                    Created {Calendar.strftime(project.inserted_at, "%b %d, %Y")}
                  </p>
                </div>
              </div>
              <.link
                navigate={~p"/projects/#{project.id}"}
                class="text-sm text-blue-500 hover:text-blue-600 transition"
              >
                View
              </.link>
            </div>
          </div>
        </div>

        <%!-- Quick Actions --%>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <.link
            navigate={~p"/templates/new"}
            class="group flex items-center gap-3 rounded-xl border border-gray-200 bg-white p-4 shadow-sm hover:shadow-md hover:border-blue-300 transition"
          >
            <div class="flex items-center justify-center w-10 h-10 rounded-lg bg-blue-50 group-hover:bg-blue-100 transition">
              <.icon name="hero-plus" class="w-5 h-5 text-blue-500" />
            </div>
            <span class="text-sm font-medium text-gray-900">New Template</span>
          </.link>

          <.link
            navigate={~p"/projects/new"}
            class="group flex items-center gap-3 rounded-xl border border-gray-200 bg-white p-4 shadow-sm hover:shadow-md hover:border-indigo-300 transition"
          >
            <div class="flex items-center justify-center w-10 h-10 rounded-lg bg-indigo-50 group-hover:bg-indigo-100 transition">
              <.icon name="hero-folder-plus" class="w-5 h-5 text-indigo-500" />
            </div>
            <span class="text-sm font-medium text-gray-900">New Project</span>
          </.link>

          <.link
            navigate={~p"/enums/new"}
            class="group flex items-center gap-3 rounded-xl border border-gray-200 bg-white p-4 shadow-sm hover:shadow-md hover:border-purple-300 transition"
          >
            <div class="flex items-center justify-center w-10 h-10 rounded-lg bg-purple-50 group-hover:bg-purple-100 transition">
              <.icon name="hero-plus-circle" class="w-5 h-5 text-purple-500" />
            </div>
            <span class="text-sm font-medium text-gray-900">New Enum</span>
          </.link>

          <.link
            navigate={~p"/generate"}
            class="group flex items-center gap-3 rounded-xl border border-gray-200 bg-white p-4 shadow-sm hover:shadow-md hover:border-green-300 transition"
          >
            <div class="flex items-center justify-center w-10 h-10 rounded-lg bg-green-50 group-hover:bg-green-100 transition">
              <.icon name="hero-play" class="w-5 h-5 text-green-500" />
            </div>
            <span class="text-sm font-medium text-gray-900">Generate Data</span>
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
