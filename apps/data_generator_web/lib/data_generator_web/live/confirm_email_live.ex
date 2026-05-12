defmodule DataGeneratorWeb.ConfirmEmailLive do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Accounts

  def mount(%{"token" => token}, _session, socket) do
    if connected?(socket) do
      case Accounts.confirm_email(token) do
        {:ok, _user} ->
          {:ok,
           assign(socket,
             page_title: "Email Confirmed",
             status: :confirmed
           )}

        {:error, _reason} ->
          {:ok,
           assign(socket,
             page_title: "Confirmation Failed",
             status: :error
           )}
      end
    else
      {:ok,
       assign(socket,
         page_title: "Confirming Email",
         status: :confirming
       )}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-md text-center">
        <%= case @status do %>
          <% :confirming -> %>
            <div class="rounded-xl border border-blue-200 bg-blue-50 p-8">
              <div class="flex items-center justify-center w-16 h-16 mx-auto rounded-full bg-blue-100">
                <.icon name="hero-arrow-path" class="w-8 h-8 text-blue-600 animate-spin" />
              </div>
              <h1 class="mt-4 text-2xl font-bold text-blue-900">Confirming your email...</h1>
              <p class="mt-2 text-sm text-blue-700">
                Please wait while we verify your email address.
              </p>
            </div>
          <% :confirmed -> %>
            <div class="rounded-xl border border-green-200 bg-green-50 p-8">
              <div class="flex items-center justify-center w-16 h-16 mx-auto rounded-full bg-green-100">
                <.icon name="hero-check-circle" class="w-8 h-8 text-green-600" />
              </div>
              <h1 class="mt-4 text-2xl font-bold text-green-900">Email confirmed!</h1>
              <p class="mt-2 text-sm text-green-700">
                Your email has been verified successfully. You can now log in.
              </p>
              <.link
                navigate={~p"/login"}
                class="mt-6 inline-block rounded-lg bg-green-600 px-6 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-green-700 transition"
              >
                Go to login
              </.link>
            </div>
          <% :error -> %>
            <div class="rounded-xl border border-red-200 bg-red-50 p-8">
              <div class="flex items-center justify-center w-16 h-16 mx-auto rounded-full bg-red-100">
                <.icon name="hero-x-circle" class="w-8 h-8 text-red-600" />
              </div>
              <h1 class="mt-4 text-2xl font-bold text-red-900">Confirmation failed</h1>
              <p class="mt-2 text-sm text-red-700">
                This confirmation link is invalid or has expired.
              </p>
              <.link
                navigate={~p"/"}
                class="mt-6 inline-block rounded-lg bg-red-600 px-6 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-red-700 transition"
              >
                Go to home
              </.link>
            </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
