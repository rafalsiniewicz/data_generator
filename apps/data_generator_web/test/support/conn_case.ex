defmodule DataGeneratorWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use DataGeneratorWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint DataGeneratorWeb.Endpoint

      use DataGeneratorWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import DataGeneratorWeb.ConnCase
      import DataGenerator.Factory
    end
  end

  setup tags do
    DataGenerator.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Creates a user and returns a conn with that user logged in via session.
  """
  def log_in_user(%Plug.Conn{} = conn, user) do
    token = Phoenix.Token.sign(DataGeneratorWeb.Endpoint, "user auth", user.id)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
    |> Plug.Conn.put_session(:live_socket_id, "users_sessions:#{user.id}")
  end

  @doc """
  Creates a user via factory, logs them in, and returns `{conn, user}`.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = DataGenerator.Factory.insert(:user)
    conn = log_in_user(conn, user)
    %{conn: conn, user: user}
  end
end
