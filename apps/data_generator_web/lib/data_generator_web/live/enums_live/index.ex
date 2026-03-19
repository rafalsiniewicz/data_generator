defmodule DataGeneratorWeb.EnumsLive.Index do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Enums

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    enums = Enums.list_user_enums(user.id)

    {:ok,
     socket
     |> assign(page_title: "Enums", search: "")
     |> stream(:enums, enums)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold text-gray-900">Custom Enums</h1>
            <p class="mt-1 text-sm text-gray-600">
              Define custom value sets to use in your data generation templates.
            </p>
          </div>
          <.link
            navigate={~p"/enums/new"}
            class="inline-flex items-center gap-1.5 rounded-lg bg-blue-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-600 transition"
          >
            <.icon name="hero-plus" class="w-4 h-4" /> New Enum
          </.link>
        </div>

        <%!-- Search Bar --%>
        <form id="enum-search" phx-change="search" class="relative">
          <.icon
            name="hero-magnifying-glass"
            class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400"
          />
          <input
            type="text"
            name="search"
            value={@search}
            placeholder="Search enums..."
            phx-debounce="300"
            class="block w-full rounded-lg border border-gray-300 bg-white pl-10 pr-4 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none"
          />
        </form>

        <div
          id="enums"
          phx-update="stream"
          class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3"
        >
          <div class="hidden only:block col-span-full rounded-xl border border-dashed border-gray-300 bg-gray-50 p-12 text-center">
            <.icon name="hero-list-bullet" class="mx-auto w-12 h-12 text-gray-400" />
            <h3 class="mt-4 text-sm font-semibold text-gray-900">No custom enums yet</h3>
            <p class="mt-1 text-sm text-gray-500">
              Create an enum to define custom value sets for data generation.
            </p>
            <.link
              navigate={~p"/enums/new"}
              class="mt-4 inline-flex items-center gap-1.5 text-sm font-semibold text-blue-500 hover:text-blue-600"
            >
              <.icon name="hero-plus" class="w-4 h-4" /> Create enum
            </.link>
          </div>

          <div
            :for={{id, enum} <- @streams.enums}
            id={id}
            class="group rounded-xl border border-gray-200 bg-white p-5 shadow-sm hover:shadow-md hover:border-blue-300 transition"
          >
            <div class="flex items-start justify-between">
              <div class="flex items-center gap-3">
                <div class="flex items-center justify-center w-10 h-10 rounded-lg bg-blue-50 group-hover:bg-blue-100 transition">
                  <.icon name="hero-list-bullet" class="w-5 h-5 text-blue-500" />
                </div>
                <div>
                  <h3 class="text-sm font-semibold text-gray-900">{enum.name}</h3>
                  <p class="text-xs text-gray-500">{length(enum.enum_values)} values</p>
                </div>
              </div>
              <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition">
                <.link
                  navigate={~p"/enums/#{enum.id}/edit"}
                  class="rounded-lg p-1.5 text-gray-400 hover:text-blue-500 hover:bg-blue-50 transition"
                  title="Edit"
                >
                  <.icon name="hero-pencil-square" class="w-4 h-4" />
                </.link>
                <button
                  phx-click="delete"
                  phx-value-id={enum.id}
                  data-confirm="Are you sure you want to delete this enum?"
                  class="rounded-lg p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 transition"
                  title="Delete"
                >
                  <.icon name="hero-trash" class="w-4 h-4" />
                </button>
              </div>
            </div>

            <%!-- Value Preview --%>
            <div class="mt-3 flex flex-wrap gap-1.5">
              <%= for value <- Elixir.Enum.take(enum.enum_values, 5) do %>
                <span class="inline-flex items-center rounded-full bg-blue-50 px-2 py-0.5 text-xs font-medium text-blue-700">
                  {value.value}
                </span>
              <% end %>
              <%= if length(enum.enum_values) > 5 do %>
                <span class="inline-flex items-center rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-500">
                  +{length(enum.enum_values) - 5} more
                </span>
              <% end %>
            </div>

            <div class="mt-3 pt-3 border-t border-gray-100 text-xs text-gray-400">
              Updated {Calendar.strftime(enum.updated_at, "%b %d, %Y")}
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("search", %{"search" => search}, socket) do
    user = socket.assigns.current_user
    enums = Enums.list_user_enums(user.id, search: search)

    {:noreply,
     socket
     |> assign(search: search)
     |> stream(:enums, enums, reset: true)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user

    # Scope deletion to the current user for security
    enum = Enums.get_user_enum!(user.id, id)

    case Enums.delete_enum(enum) do
      {:ok, _} ->
        {:noreply,
         socket
         |> stream_delete(:enums, enum)
         |> put_flash(:info, "Enum \"#{enum.name}\" deleted successfully.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete enum.")}
    end
  end
end
