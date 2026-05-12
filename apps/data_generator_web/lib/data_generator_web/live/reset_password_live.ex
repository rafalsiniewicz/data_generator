defmodule DataGeneratorWeb.ResetPasswordLive do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Accounts

  def mount(%{"token" => token}, _session, socket) do
    form = to_form(%{"password" => ""}, as: :user)

    {:ok,
     assign(socket,
       form: form,
       token: token,
       page_title: "Reset Password"
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-md">
        <div class="text-center">
          <h1 class="text-2xl font-bold tracking-tight text-gray-900">Reset your password</h1>
          <p class="mt-2 text-sm text-gray-600">Enter your new password below.</p>
        </div>

        <div class="mt-8 rounded-xl border border-gray-200 bg-white p-8 shadow-sm">
          <.form for={@form} id="reset-password-form" phx-submit="reset_password" class="space-y-6">
            <.input
              field={@form[:password]}
              type="password"
              label="New password"
              required
              autocomplete="new-password"
            />
            <.button
              type="submit"
              phx-disable-with="Resetting..."
              class="w-full rounded-lg bg-blue-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-600 transition"
            >
              Reset password
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("reset_password", %{"user" => %{"password" => password}}, socket) do
    case Accounts.reset_password(socket.assigns.token, %{"password" => password}) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully. You can now log in.")
         |> push_navigate(to: ~p"/login")}

      {:error, :invalid_token} ->
        {:noreply,
         socket
         |> put_flash(:error, "Reset link is invalid or has expired.")
         |> push_navigate(to: ~p"/forgot-password")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :user))}
    end
  end
end
