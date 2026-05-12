defmodule DataGeneratorWeb.Router do
  use DataGeneratorWeb, :router

  import DataGeneratorWeb.Plugs.Auth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DataGeneratorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes (no auth required) — non-LiveView
  scope "/", DataGeneratorWeb do
    pipe_through :browser

    # Session routes (plain controller actions)
    post "/login", UserSessionController, :create
    delete "/logout", UserSessionController, :delete
  end

  # LiveView routes that redirect if already authenticated
  scope "/", DataGeneratorWeb do
    pipe_through :browser

    live_session :redirect_if_authenticated,
      on_mount: [{DataGeneratorWeb.LiveHelpers, :redirect_if_authenticated}] do
      live "/login", LoginLive
      live "/register", RegisterLive
      live "/forgot-password", ForgotPasswordLive
      live "/reset-password/:token", ResetPasswordLive
    end
  end

  # Public LiveView routes (optional auth)
  scope "/", DataGeneratorWeb do
    pipe_through :browser

    live_session :public,
      on_mount: [{DataGeneratorWeb.LiveHelpers, :default}] do
      live "/", HomeLive
      live "/generate", GenerateDataLive
      live "/confirm-email/:token", ConfirmEmailLive
    end
  end

  # Authenticated LiveView routes
  scope "/", DataGeneratorWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: [{DataGeneratorWeb.LiveHelpers, :require_authenticated}] do
      live "/dashboard", DashboardLive
      live "/templates", TemplatesLive.Index
      live "/templates/new", TemplatesLive.New
      live "/templates/:id/edit", TemplatesLive.Edit
      live "/projects", ProjectsLive.Index
      live "/projects/new", ProjectsLive.New
      live "/projects/:id", ProjectsLive.Show
      live "/projects/:id/members", ProjectsLive.Members
      live "/enums", EnumsLive.Index
      live "/enums/new", EnumsLive.New
      live "/enums/:id/edit", EnumsLive.Edit
      live "/settings", SettingsLive
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:data_generator_web, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DataGeneratorWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
