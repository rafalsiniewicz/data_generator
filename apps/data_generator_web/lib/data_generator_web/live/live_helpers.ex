defmodule DataGeneratorWeb.LiveHelpers do
  @moduledoc """
  LiveView on_mount hooks for session-based authentication.

  Provides three mount strategies:

  - `:default` — assigns current_user if present, does not block
  - `:require_authenticated` — redirects to `/login` if not authenticated
  - `:redirect_if_authenticated` — redirects to `/dashboard` if already logged in
  """

  import Phoenix.LiveView
  import Phoenix.Component

  alias DataGenerator.Accounts

  @salt "user auth"
  @max_age 60 * 60 * 24 * 60

  @doc """
  Default mount hook. Assigns `current_user` and `current_scope` without
  enforcing authentication.
  """
  def on_mount(:default, _params, session, socket) do
    socket = assign_current_user(socket, session)
    {:cont, socket}
  end

  def on_mount(:require_authenticated, _params, session, socket) do
    socket = assign_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt,
       socket
       |> put_flash(:error, "You must log in to access this page.")
       |> redirect(to: "/login")}
    end
  end

  def on_mount(:redirect_if_authenticated, _params, session, socket) do
    socket = assign_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, socket |> redirect(to: "/dashboard")}
    else
      {:cont, socket}
    end
  end

  defp assign_current_user(socket, session) do
    case session["user_token"] do
      nil ->
        socket
        |> assign(:current_user, nil)
        |> assign(:current_scope, nil)

      token ->
        case Phoenix.Token.verify(DataGeneratorWeb.Endpoint, @salt, token, max_age: @max_age) do
          {:ok, user_id} ->
            user = Accounts.get_user(user_id)

            socket
            |> assign(:current_user, user)
            |> assign(:current_scope, user && %{user: user})

          {:error, _} ->
            socket
            |> assign(:current_user, nil)
            |> assign(:current_scope, nil)
        end
    end
  end
end
