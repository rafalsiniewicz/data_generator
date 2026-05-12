defmodule DataGeneratorWeb.Layouts do
  @moduledoc """
  Layout components for the Data Generator application.

  Provides the root layout (embedded template) and the `app/1` layout
  which wraps every page with a responsive sidebar + topbar navigation.
  """
  use DataGeneratorWeb, :html

  embed_templates "layouts/*"

  @doc """
  Renders the main application layout with sidebar navigation.

  Authenticated users see the full sidebar with Dashboard, Generate Data,
  Templates, Projects, Enums, and Settings links plus a logout action.
  Unauthenticated users see a minimal topbar with Login / Register.

  ## Examples

      <Layouts.app flash={@flash} current_scope={@current_scope}>
        <h1>Content</h1>
      </Layouts.app>
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current scope containing the user"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <%= if @current_scope do %>
      <%!-- Authenticated layout with sidebar --%>
      <div class="min-h-screen bg-gray-50 flex">
        <%!-- Sidebar --%>
        <aside class="hidden lg:flex lg:flex-col lg:w-64 lg:fixed lg:inset-y-0 bg-white border-r border-gray-200">
          <%!-- Logo --%>
          <div class="flex items-center gap-2.5 h-16 px-6 border-b border-gray-200">
            <div class="flex items-center justify-center w-8 h-8 rounded-lg bg-blue-500">
              <.icon name="hero-cube-transparent" class="w-5 h-5 text-white" />
            </div>
            <span class="text-lg font-bold text-gray-900 tracking-tight">Data Generator</span>
          </div>

          <%!-- Navigation --%>
          <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
            <.sidebar_link href={~p"/dashboard"} icon="hero-squares-2x2" label="Dashboard" />
            <.sidebar_link href={~p"/generate"} icon="hero-bolt" label="Generate Data" />

            <div class="pt-4 pb-2">
              <p class="px-3 text-xs font-semibold uppercase tracking-wider text-gray-400">
                Manage
              </p>
            </div>
            <.sidebar_link href={~p"/templates"} icon="hero-document-duplicate" label="Templates" />
            <.sidebar_link href={~p"/projects"} icon="hero-folder" label="Projects" />
            <.sidebar_link href={~p"/enums"} icon="hero-list-bullet" label="Enums" />

            <div class="pt-4 pb-2">
              <p class="px-3 text-xs font-semibold uppercase tracking-wider text-gray-400">
                Account
              </p>
            </div>
            <.sidebar_link href={~p"/settings"} icon="hero-cog-6-tooth" label="Settings" />
          </nav>

          <%!-- User info + Logout --%>
          <div class="border-t border-gray-200 px-4 py-4">
            <div class="flex items-center gap-3">
              <div class="flex items-center justify-center w-8 h-8 rounded-full bg-blue-100 text-sm font-bold text-blue-600">
                {String.first(@current_scope.user.login)}
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium text-gray-900 truncate">{@current_scope.user.login}</p>
                <p class="text-xs text-gray-500 truncate">{@current_scope.user.email}</p>
              </div>
              <.link
                href={~p"/logout"}
                method="delete"
                class="rounded-lg p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 transition"
                title="Log out"
              >
                <.icon name="hero-arrow-right-on-rectangle" class="w-5 h-5" />
              </.link>
            </div>
          </div>
        </aside>

        <%!-- Main content area --%>
        <div class="lg:pl-64 flex-1 flex flex-col min-h-screen">
          <%!-- Mobile topbar --%>
          <header class="lg:hidden sticky top-0 z-40 flex items-center justify-between h-14 px-4 bg-white border-b border-gray-200">
            <div class="flex items-center gap-2">
              <div class="flex items-center justify-center w-7 h-7 rounded-lg bg-blue-500">
                <.icon name="hero-cube-transparent" class="w-4 h-4 text-white" />
              </div>
              <span class="text-base font-bold text-gray-900">Data Generator</span>
            </div>
            <nav class="flex items-center gap-2">
              <.link
                navigate={~p"/dashboard"}
                class="p-2 text-gray-500 hover:text-gray-700 transition"
              >
                <.icon name="hero-squares-2x2" class="w-5 h-5" />
              </.link>
              <.link navigate={~p"/generate"} class="p-2 text-gray-500 hover:text-gray-700 transition">
                <.icon name="hero-bolt" class="w-5 h-5" />
              </.link>
              <.link navigate={~p"/settings"} class="p-2 text-gray-500 hover:text-gray-700 transition">
                <.icon name="hero-cog-6-tooth" class="w-5 h-5" />
              </.link>
              <.link
                href={~p"/logout"}
                method="delete"
                class="p-2 text-gray-400 hover:text-red-500 transition"
              >
                <.icon name="hero-arrow-right-on-rectangle" class="w-5 h-5" />
              </.link>
            </nav>
          </header>

          <main class="flex-1 px-4 py-8 sm:px-6 lg:px-8">
            <div class="mx-auto max-w-6xl">
              {render_slot(@inner_block)}
            </div>
          </main>
        </div>
      </div>
    <% else %>
      <%!-- Unauthenticated layout with topbar --%>
      <div class="min-h-screen bg-gray-50 flex flex-col">
        <header class="sticky top-0 z-40 bg-white/80 backdrop-blur-lg border-b border-gray-200">
          <div class="mx-auto max-w-6xl flex items-center justify-between h-16 px-4 sm:px-6 lg:px-8">
            <.link navigate={~p"/"} class="flex items-center gap-2.5">
              <div class="flex items-center justify-center w-8 h-8 rounded-lg bg-blue-500">
                <.icon name="hero-cube-transparent" class="w-5 h-5 text-white" />
              </div>
              <span class="text-lg font-bold text-gray-900 tracking-tight">Data Generator</span>
            </.link>
            <nav class="flex items-center gap-3">
              <.link
                navigate={~p"/login"}
                class="text-sm font-medium text-gray-600 hover:text-gray-900 transition"
              >
                Log in
              </.link>
              <.link
                navigate={~p"/register"}
                class="rounded-lg bg-blue-500 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-600 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 transition"
              >
                Sign up
              </.link>
            </nav>
          </div>
        </header>

        <main class="flex-1 px-4 py-8 sm:px-6 lg:px-8">
          <div class="mx-auto max-w-6xl">
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>
    <% end %>

    <.flash_group flash={@flash} />
    """
  end

  @doc false
  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true

  defp sidebar_link(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 hover:text-gray-900 transition"
    >
      <.icon name={@icon} class="w-5 h-5 text-gray-400" />
      {@label}
    </.link>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end
end
