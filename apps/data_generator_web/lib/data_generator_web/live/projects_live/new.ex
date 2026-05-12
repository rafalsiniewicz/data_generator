defmodule DataGeneratorWeb.ProjectsLive.New do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Projects
  alias DataGenerator.Projects.Project

  def mount(_params, _session, socket) do
    changeset = Projects.change_project(%Project{})

    {:ok,
     assign(socket,
       page_title: "New Project",
       form: to_form(changeset, as: :project)
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6 max-w-xl">
        <div>
          <.link
            navigate={~p"/projects"}
            class="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 transition mb-2"
          >
            <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Projects
          </.link>
          <h1 class="text-2xl font-bold text-gray-900">New Project</h1>
          <p class="mt-1 text-sm text-gray-600">
            Create a new project to organize your templates and collaborate with others.
          </p>
        </div>

        <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
          <.form
            for={@form}
            id="project-form"
            phx-submit="save"
            phx-change="validate"
            class="space-y-6"
          >
            <.input
              field={@form[:name]}
              type="text"
              label="Project Name"
              required
              phx-debounce="blur"
              placeholder="My Data Project"
            />

            <div class="flex items-center justify-end gap-3 pt-4 border-t border-gray-100">
              <.link
                navigate={~p"/projects"}
                class="rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-semibold text-gray-700 shadow-sm hover:bg-gray-50 transition"
              >
                Cancel
              </.link>
              <.button
                type="submit"
                phx-disable-with="Creating..."
                class="rounded-lg bg-blue-500 px-6 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-600 transition"
              >
                Create Project
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset =
      %Project{}
      |> Projects.change_project(project_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: :project))}
  end

  def handle_event("save", %{"project" => project_params}, socket) do
    user = socket.assigns.current_user

    case Projects.create_project(user.id, project_params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully.")
         |> push_navigate(to: ~p"/projects/#{project.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :project))}
    end
  end
end
