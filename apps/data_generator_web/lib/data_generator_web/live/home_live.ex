defmodule DataGeneratorWeb.HomeLive do
  use DataGeneratorWeb, :live_view

  def mount(_params, _session, socket) do
    if socket.assigns[:current_user] do
      {:ok, push_navigate(socket, to: ~p"/dashboard")}
    else
      {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="text-center py-20">
        <h1 class="text-5xl font-bold tracking-tight text-gray-900">Data Generator</h1>
        <p class="mt-6 text-lg leading-8 text-gray-600 max-w-2xl mx-auto">
          Generate millions of realistic mock data rows instantly.
          Export to CSV, JSON, or SQL — no sign-up required.
        </p>
        <div class="mt-10 flex items-center justify-center gap-x-6">
          <.link
            navigate={~p"/generate"}
            class="text-sm font-semibold text-gray-900 hover:text-blue-500 transition"
          >
            Generate Ad-Hoc Data <span aria-hidden="true">&rarr;</span>
          </.link>
        </div>

        <div class="mt-24 grid grid-cols-1 gap-8 sm:grid-cols-3 max-w-4xl mx-auto">
          <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm hover:shadow-md transition">
            <div class="flex items-center justify-center w-12 h-12 mx-auto rounded-full bg-blue-50">
              <.icon name="hero-table-cells" class="w-6 h-6 text-blue-500" />
            </div>
            <h3 class="mt-4 text-lg font-semibold text-gray-900">20+ Data Types</h3>
            <p class="mt-2 text-sm text-gray-600">
              Names, emails, addresses, numbers, dates, UUIDs, custom enums, and more.
            </p>
          </div>
          <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm hover:shadow-md transition">
            <div class="flex items-center justify-center w-12 h-12 mx-auto rounded-full bg-blue-50">
              <.icon name="hero-bolt" class="w-6 h-6 text-blue-500" />
            </div>
            <h3 class="mt-4 text-lg font-semibold text-gray-900">Blazing Fast</h3>
            <p class="mt-2 text-sm text-gray-600">
              Parallel generation engine handles millions of rows with ease.
            </p>
          </div>
          <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm hover:shadow-md transition">
            <div class="flex items-center justify-center w-12 h-12 mx-auto rounded-full bg-blue-50">
              <.icon name="hero-arrow-down-tray" class="w-6 h-6 text-blue-500" />
            </div>
            <h3 class="mt-4 text-lg font-semibold text-gray-900">Multiple Formats</h3>
            <p class="mt-2 text-sm text-gray-600">
              Export your generated data as CSV, JSON, or SQL INSERT statements.
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
