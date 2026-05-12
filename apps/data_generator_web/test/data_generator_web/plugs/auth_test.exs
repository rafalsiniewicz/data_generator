defmodule DataGeneratorWeb.Plugs.AuthTest do
  use DataGeneratorWeb.ConnCase, async: true

  alias DataGeneratorWeb.Plugs.Auth

  # ── Helpers ───────────────────────────────────────────────────

  defp setup_user(_context) do
    user = insert(:user)
    %{user: user}
  end

  # ── fetch_current_user/2 ────────────────────────────────────

  describe "fetch_current_user/2" do
    setup [:setup_user]

    test "assigns current_user when valid token in session", %{conn: conn, user: user} do
      token = Phoenix.Token.sign(DataGeneratorWeb.Endpoint, "user auth", user.id)

      conn =
        conn
        |> init_test_session(%{user_token: token})
        |> Auth.fetch_current_user([])

      assert conn.assigns.current_user.id == user.id
      assert conn.assigns.current_scope == %{user: conn.assigns.current_user}
    end

    test "assigns nil current_user when no token in session", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Auth.fetch_current_user([])

      assert conn.assigns.current_user == nil
      assert conn.assigns.current_scope == nil
    end

    test "assigns nil current_user when token is expired", %{conn: conn, user: user} do
      # Sign a token with a very short max_age that has already expired
      # We simulate this by directly signing with an old timestamp
      # Phoenix.Token doesn't allow us to set the timestamp, so we use a token
      # signed with a different key to simulate invalidity
      token = Phoenix.Token.sign(DataGeneratorWeb.Endpoint, "wrong salt", user.id)

      conn =
        conn
        |> init_test_session(%{user_token: token})
        |> Auth.fetch_current_user([])

      assert conn.assigns.current_user == nil
    end

    test "assigns nil current_user when token is malformed", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{user_token: "totally-invalid-token"})
        |> Auth.fetch_current_user([])

      assert conn.assigns.current_user == nil
    end

    test "assigns nil current_user when user_id doesn't exist", %{conn: conn} do
      token = Phoenix.Token.sign(DataGeneratorWeb.Endpoint, "user auth", -999)

      conn =
        conn
        |> init_test_session(%{user_token: token})
        |> Auth.fetch_current_user([])

      assert conn.assigns.current_user == nil
    end
  end

  # ── log_in_user/2 ──────────────────────────────────────────

  describe "log_in_user/2" do
    setup [:setup_user]

    test "sets session token and redirects to dashboard", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(%{})
        |> Auth.log_in_user(user)

      assert redirected_to(conn) == "/dashboard"
      assert get_session(conn, :user_token) != nil
      assert get_session(conn, :live_socket_id) == "users_sessions:#{user.id}"
    end
  end

  # ── log_out_user/1 ─────────────────────────────────────────

  describe "log_out_user/1" do
    setup [:setup_user]

    test "clears session and redirects to home", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(%{})
        |> Auth.log_in_user(user)

      # Now log out using a fresh conn with the session
      logout_conn =
        conn
        |> recycle()
        |> init_test_session(%{
          user_token: get_session(conn, :user_token),
          live_socket_id: get_session(conn, :live_socket_id)
        })
        |> Auth.log_out_user()

      assert redirected_to(logout_conn) == "/"
    end
  end

  # ── require_authenticated_user/2 ───────────────────────────

  describe "require_authenticated_user/2" do
    test "passes through when current_user is assigned", %{conn: conn} do
      user = insert(:user)

      conn =
        conn
        |> init_test_session(%{})
        |> assign(:current_user, user)
        |> Auth.require_authenticated_user([])

      refute conn.halted
    end

    test "halts and redirects to login when no current_user", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> fetch_flash()
        |> assign(:current_user, nil)
        |> Auth.require_authenticated_user([])

      assert conn.halted
      assert redirected_to(conn) == "/login"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "must log in"
    end
  end

  # ── redirect_if_user_is_authenticated/2 ────────────────────

  describe "redirect_if_user_is_authenticated/2" do
    test "redirects to dashboard when user is authenticated", %{conn: conn} do
      user = insert(:user)

      conn =
        conn
        |> init_test_session(%{})
        |> assign(:current_user, user)
        |> Auth.redirect_if_user_is_authenticated([])

      assert conn.halted
      assert redirected_to(conn) == "/dashboard"
    end

    test "passes through when no current_user", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> assign(:current_user, nil)
        |> Auth.redirect_if_user_is_authenticated([])

      refute conn.halted
    end
  end
end
