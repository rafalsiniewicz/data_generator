defmodule DataGeneratorWeb.ForgotPasswordLive do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Accounts
  alias DataGenerator.Accounts.UserNotifier

  def mount(_params, _session, socket) do
    form = to_form(%{"email" => ""}, as: :user)

    {:ok,
     assign(socket,
       form: form,
       page_title: "Forgot Password",
       email_sent: false
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-md">
        <div class="text-center">
          <h1 class="text-2xl font-bold tracking-tight text-gray-900">Forgot your password?</h1>
          <p class="mt-2 text-sm text-gray-600">
            Enter your email and we'll send you a reset link.
          </p>
        </div>

        <%= if @email_sent do %>
          <div class="mt-8 rounded-xl border border-blue-200 bg-blue-50 p-8 text-center">
            <div class="flex items-center justify-center w-12 h-12 mx-auto rounded-full bg-blue-100">
              <.icon name="hero-envelope" class="w-6 h-6 text-blue-600" />
            </div>
            <h2 class="mt-4 text-lg font-semibold text-blue-900">Check your email</h2>
            <p class="mt-2 text-sm text-blue-700">
              If an account exists with that email, we've sent password reset instructions.
            </p>
            <.link
              navigate={~p"/login"}
              class="mt-4 inline-block text-sm font-semibold text-blue-500 hover:text-blue-600"
            >
              Back to login
            </.link>
          </div>
        <% else %>
          <div class="mt-8 rounded-xl border border-gray-200 bg-white p-8 shadow-sm">
            <.form for={@form} id="forgot-password-form" phx-submit="send_reset" class="space-y-6">
              <.input
                field={@form[:email]}
                type="email"
                label="Email address"
                required
                autocomplete="email"
              />
              <.button
                type="submit"
                phx-disable-with="Sending..."
                class="w-full rounded-lg bg-blue-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-600 transition"
              >
                Send reset instructions
              </.button>
            </.form>
            <p class="mt-4 text-center text-sm text-gray-600">
              <.link navigate={~p"/login"} class="font-semibold text-blue-500 hover:text-blue-600">
                Back to login
              </.link>
            </p>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("send_reset", %{"user" => %{"email" => email}}, socket) do
    case Accounts.request_password_reset(email) do
      {:ok, token} when is_binary(token) ->
        user = Accounts.get_user_by_email(email)
        url = url(socket, ~p"/reset-password/#{token}")
        UserNotifier.deliver_password_reset_instructions(user, url)

      {:ok, nil} ->
        :ok
    end

    # Always show success message to prevent email enumeration
    {:noreply, assign(socket, email_sent: true)}
  end
end
