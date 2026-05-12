defmodule DataGeneratorWeb.UserSessionController do
  @moduledoc """
  Controller for session-based login and logout actions.
  """

  use DataGeneratorWeb, :controller

  alias DataGenerator.Accounts
  alias DataGeneratorWeb.Plugs.Auth

  @doc """
  Handles login form submission. Authenticates the user by email/login
  and password, then sets up the session via `Auth.log_in_user/2`.
  """
  def create(conn, %{"user" => %{"email_or_login" => email_or_login, "password" => password}}) do
    case Accounts.authenticate_user(email_or_login, password) do
      {:ok, user} ->
        Auth.log_in_user(conn, user)

      {:error, :email_not_confirmed} ->
        conn
        |> put_flash(:error, "Please confirm your email address before logging in")
        |> redirect(to: ~p"/login")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid email/username or password")
        |> redirect(to: ~p"/login")
    end
  end

  @doc """
  Logs the user out by clearing the session.
  """
  def delete(conn, _params) do
    Auth.log_out_user(conn)
  end
end
