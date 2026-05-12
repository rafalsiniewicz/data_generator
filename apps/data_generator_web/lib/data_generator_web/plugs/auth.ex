defmodule DataGeneratorWeb.Plugs.Auth do
  @moduledoc """
  Authentication plug for session-based auth in the LiveView frontend.

  Handles fetching the current user from the session, logging in/out,
  and route-level authentication guards.

  Uses `Phoenix.Token` to sign/verify user IDs stored in the session.
  """

  use DataGeneratorWeb, :verified_routes
  import Plug.Conn
  import Phoenix.Controller

  alias DataGenerator.Accounts

  # Max age of session tokens (60 days)
  @max_age 60 * 60 * 24 * 60
  @salt "user auth"

  @doc """
  Reads `user_token` from the session, verifies it, looks up the user,
  and assigns `:current_user` and `:current_scope` to the conn.
  """
  def fetch_current_user(conn, _opts) do
    {user_id, conn} = ensure_user_token(conn)
    user = user_id && Accounts.get_user(user_id)

    conn
    |> assign(:current_user, user)
    |> assign(:current_scope, user && %{user: user})
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      case Phoenix.Token.verify(DataGeneratorWeb.Endpoint, @salt, token, max_age: @max_age) do
        {:ok, user_id} -> {user_id, conn}
        {:error, _} -> {nil, conn}
      end
    else
      {nil, conn}
    end
  end

  @doc """
  Logs a user in by signing a Phoenix.Token with their user ID,
  storing it in the session, and redirecting to `/dashboard`.
  """
  def log_in_user(conn, user) do
    token = Phoenix.Token.sign(DataGeneratorWeb.Endpoint, @salt, user.id)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{user.id}")
    |> redirect(to: ~p"/dashboard")
  end

  @doc """
  Logs out the user by clearing the session and broadcasting
  a disconnect to any connected LiveView sockets.
  """
  def log_out_user(conn) do
    if live_socket_id = get_session(conn, :live_socket_id) do
      DataGeneratorWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> redirect(to: ~p"/")
  end

  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Plug that requires the user to be authenticated.
  Redirects to `/login` with a flash message if not.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: ~p"/login")
      |> halt()
    end
  end

  @doc """
  Plug that redirects already-authenticated users away from
  login/register pages to `/dashboard`.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: ~p"/dashboard")
      |> halt()
    else
      conn
    end
  end
end
