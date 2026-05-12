defmodule DataGeneratorWeb.RegisterLive do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Accounts
  alias DataGenerator.Accounts.User
  alias DataGenerator.Accounts.UserNotifier

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})
    form = to_form(changeset, as: :user)

    {:ok,
     assign(socket,
       form: form,
       page_title: "Create Account",
       check_email: false
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-md">
        <div class="text-center">
          <h1 class="text-2xl font-bold tracking-tight text-gray-900">Create your account</h1>
          <p class="mt-2 text-sm text-gray-600">
            Already have an account?
            <.link navigate={~p"/login"} class="font-semibold text-blue-500 hover:text-blue-600">
              Log in
            </.link>
          </p>
        </div>

        <%= if @check_email do %>
          <div class="mt-8 rounded-xl border border-green-200 bg-green-50 p-8 text-center">
            <div class="flex items-center justify-center w-12 h-12 mx-auto rounded-full bg-green-100">
              <.icon name="hero-envelope" class="w-6 h-6 text-green-600" />
            </div>
            <h2 class="mt-4 text-lg font-semibold text-green-900">Check your email</h2>
            <p class="mt-2 text-sm text-green-700">
              We sent a confirmation link to your email address.
              Please check your inbox and click the link to verify your account.
            </p>
          </div>
        <% else %>
          <div class="mt-8 rounded-xl border border-gray-200 bg-white p-8 shadow-sm">
            <.form
              for={@form}
              id="registration-form"
              phx-submit="register"
              phx-change="validate"
              class="space-y-6"
            >
              <.input
                field={@form[:login]}
                type="text"
                label="Username"
                required
                autocomplete="username"
                phx-debounce="blur"
              />
              <.input
                field={@form[:email]}
                type="email"
                label="Email"
                required
                autocomplete="email"
                phx-debounce="blur"
              />
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                required
                autocomplete="new-password"
                phx-debounce="blur"
              />

              <.button
                type="submit"
                phx-disable-with="Creating account..."
                class="w-full rounded-lg bg-blue-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-600 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 transition"
              >
                Create account
              </.button>
            </.form>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @spec handle_event(<<_::64>>, map(), any()) :: {:noreply, any()}
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: :user))}
  end

  def handle_event("register", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        token = Accounts.generate_email_token(user, "confirm_email")
        url = url(socket, ~p"/confirm-email/#{token}")
        UserNotifier.deliver_confirmation_instructions(user, url)
        {:noreply, assign(socket, check_email: true)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :user))}
    end
  end
end
