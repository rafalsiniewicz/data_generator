defmodule DataGeneratorWeb.TemplatesLive.Index do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Templates

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    templates = Templates.list_user_templates(user.id)

    {:ok,
     socket
     |> assign(page_title: "Templates", search: "")
     |> stream(:templates, templates)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold text-gray-900">Templates</h1>
            <p class="mt-1 text-sm text-gray-600">
              Saved data generation templates with column definitions.
            </p>
          </div>
          <.link
            navigate={~p"/templates/new"}
            class="inline-flex items-center gap-1.5 rounded-lg bg-blue-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-600 transition"
          >
            <.icon name="hero-plus" class="w-4 h-4" /> New Template
          </.link>
        </div>

        <%!-- Search bar --%>
        <div>
          <form phx-change="search" class="relative">
            <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
              <.icon name="hero-magnifying-glass" class="w-4 h-4 text-gray-400" />
            </div>
            <input
              type="text"
              name="search"
              id="template-search"
              value={@search}
              placeholder="Search templates..."
              phx-debounce="300"
              class="block w-full rounded-lg border border-gray-300 py-2 pl-10 pr-3 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
          </form>
        </div>

        <div
          id="templates"
          phx-update="stream"
          class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3"
        >
          <div class="hidden only:block col-span-full rounded-xl border border-dashed border-gray-300 bg-gray-50 p-12 text-center">
            <.icon name="hero-document-duplicate" class="mx-auto w-12 h-12 text-gray-400" />
            <h3 class="mt-4 text-sm font-semibold text-gray-900">No templates yet</h3>
            <p class="mt-1 text-sm text-gray-500">Get started by creating a new template.</p>
            <.link
              navigate={~p"/templates/new"}
              class="mt-4 inline-flex items-center gap-1.5 text-sm font-semibold text-blue-500 hover:text-blue-600"
            >
              <.icon name="hero-plus" class="w-4 h-4" /> Create template
            </.link>
          </div>

          <div
            :for={{id, template} <- @streams.templates}
            id={id}
            class="group rounded-xl border border-gray-200 bg-white p-5 shadow-sm hover:shadow-md hover:border-blue-300 transition"
          >
            <div class="flex items-start justify-between">
              <div class="flex items-center gap-3">
                <div class="flex items-center justify-center w-10 h-10 rounded-lg bg-blue-50 group-hover:bg-blue-100 transition">
                  <.icon name="hero-document-duplicate" class="w-5 h-5 text-blue-500" />
                </div>
                <div>
                  <h3 class="text-sm font-semibold text-gray-900">{template.name}</h3>
                  <p class="text-xs text-gray-500">
                    {length(template.columns)} columns &middot; {template.number_of_rows} rows
                  </p>
                </div>
              </div>
              <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition">
                <.link
                  navigate={~p"/templates/#{template.id}/edit"}
                  class="rounded-lg p-1.5 text-gray-400 hover:text-blue-500 hover:bg-blue-50 transition"
                >
                  <.icon name="hero-pencil-square" class="w-4 h-4" />
                </.link>
                <button
                  phx-click="delete"
                  phx-value-id={template.id}
                  data-confirm="Are you sure you want to delete this template?"
                  class="rounded-lg p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 transition"
                >
                  <.icon name="hero-trash" class="w-4 h-4" />
                </button>
              </div>
            </div>
            <%= if template.description do %>
              <p class="mt-3 text-xs text-gray-600 line-clamp-2">{template.description}</p>
            <% end %>
            <div class="mt-3 pt-3 border-t border-gray-100 text-xs text-gray-400">
              Updated {Calendar.strftime(template.updated_at, "%b %d, %Y")}
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("search", %{"search" => search}, socket) do
    user = socket.assigns.current_user
    templates = Templates.list_user_templates(user.id, search: search)

    {:noreply,
     socket
     |> assign(search: search)
     |> stream(:templates, templates, reset: true)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    template = Templates.get_user_template!(user.id, id)

    case Templates.delete_template(template) do
      {:ok, _} ->
        {:noreply,
         socket
         |> stream_delete(:templates, template)
         |> put_flash(:info, "Template deleted successfully.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete template.")}
    end
  end
end
