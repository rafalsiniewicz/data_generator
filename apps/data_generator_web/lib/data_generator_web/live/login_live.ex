defmodule DataGeneratorWeb.LoginLive do
  use DataGeneratorWeb, :live_view

  def mount(_params, _session, socket) do
    form = to_form(%{"email_or_login" => "", "password" => ""}, as: :user)
    {:ok, assign(socket, form: form, page_title: "Log In")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-md">
        <div class="text-center">
          <h1 class="text-2xl font-bold tracking-tight text-gray-900">Welcome back</h1>
          <p class="mt-2 text-sm text-gray-600">
            Don't have an account?
            <.link navigate={~p"/register"} class="font-semibold text-blue-500 hover:text-blue-600">
              Sign up
            </.link>
          </p>
        </div>

        <div class="mt-8 rounded-xl border border-gray-200 bg-white p-8 shadow-sm">
          <.form for={@form} id="login-form" action={~p"/login"} method="post" class="space-y-6">
            <.input
              field={@form[:email_or_login]}
              type="text"
              label="Email or Username"
              required
              autocomplete="username"
            />
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              required
              autocomplete="current-password"
            />

            <div class="flex items-center justify-between">
              <label class="flex items-center gap-2 text-sm text-gray-600">
                <input
                  type="checkbox"
                  name="user[remember_me]"
                  class="rounded border-gray-300 text-blue-500 focus:ring-blue-500"
                /> Remember me
              </label>
              <.link
                navigate={~p"/forgot-password"}
                class="text-sm font-semibold text-blue-500 hover:text-blue-600"
              >
                Forgot password?
              </.link>
            </div>

            <.button
              type="submit"
              class="w-full rounded-lg bg-blue-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-600 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 transition"
            >
              Log in
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
