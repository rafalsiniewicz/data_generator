defmodule DataGeneratorWeb.SettingsLive do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Accounts

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    password_form = to_form(%{"current_password" => "", "password" => ""}, as: :password)

    {:ok,
     assign(socket,
       page_title: "Settings",
       password_form: password_form,
       user: user
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8 max-w-2xl">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Settings</h1>
          <p class="mt-1 text-sm text-gray-600">Manage your account settings.</p>
        </div>

        <%!-- Account Info --%>
        <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
          <h2 class="text-lg font-semibold text-gray-900">Account Information</h2>
          <dl class="mt-4 divide-y divide-gray-100">
            <div class="flex justify-between py-3">
              <dt class="text-sm font-medium text-gray-500">Username</dt>
              <dd class="text-sm text-gray-900">{@user.login}</dd>
            </div>
            <div class="flex justify-between py-3">
              <dt class="text-sm font-medium text-gray-500">Email</dt>
              <dd class="text-sm text-gray-900">{@user.email}</dd>
            </div>
            <div class="flex justify-between py-3">
              <dt class="text-sm font-medium text-gray-500">Member since</dt>
              <dd class="text-sm text-gray-900">
                {Calendar.strftime(@user.inserted_at, "%B %d, %Y")}
              </dd>
            </div>
          </dl>
        </div>

        <%!-- Change Password --%>
        <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
          <h2 class="text-lg font-semibold text-gray-900">Change Password</h2>
          <p class="mt-1 text-sm text-gray-600">Update your password to keep your account secure.</p>

          <.form
            for={@password_form}
            id="password-form"
            phx-submit="change_password"
            class="mt-6 space-y-4"
          >
            <.input
              field={@password_form[:current_password]}
              type="password"
              label="Current password"
              required
              autocomplete="current-password"
            />
            <.input
              field={@password_form[:password]}
              type="password"
              label="New password"
              required
              autocomplete="new-password"
            />
            <div class="pt-2">
              <.button
                type="submit"
                phx-disable-with="Updating..."
                class="rounded-lg bg-blue-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-600 transition"
              >
                Update password
              </.button>
            </div>
          </.form>
        </div>

        <%!-- Danger Zone --%>
        <div class="rounded-xl border border-red-200 bg-white p-6 shadow-sm">
          <h2 class="text-lg font-semibold text-red-900">Danger Zone</h2>
          <p class="mt-1 text-sm text-gray-600">
            Permanently delete your account and all associated data.
          </p>
          <div class="mt-4">
            <button
              phx-click="delete_account"
              data-confirm="Are you sure? This action cannot be undone."
              class="rounded-lg border border-red-300 bg-white px-4 py-2 text-sm font-semibold text-red-600 shadow-sm hover:bg-red-50 transition"
            >
              Delete my account
            </button>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("change_password", %{"password" => password_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.change_password(user, password_params) do
      {:ok, _user} ->
        password_form = to_form(%{"current_password" => "", "password" => ""}, as: :password)

        {:noreply,
         socket
         |> put_flash(:info, "Password updated successfully.")
         |> assign(password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset, as: :password))}
    end
  end

  def handle_event("delete_account", _params, socket) do
    user = socket.assigns.current_user

    case Accounts.delete_user(user) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Your account has been deleted.")
         |> redirect(to: ~p"/")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not delete your account. Please try again.")}
    end
  end
end
