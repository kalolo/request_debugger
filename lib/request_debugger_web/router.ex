defmodule RequestDebuggerWeb.Router do
  use RequestDebuggerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RequestDebuggerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :catch_all do
    plug :put_secure_browser_headers
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:request_debugger, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RequestDebuggerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", RequestDebuggerWeb do
    pipe_through :browser

    get "/", RedirectController, :to_incoming
    live "/incoming", IncomingLive
  end

  scope "/catch", RequestDebuggerWeb do
    pipe_through :catch_all

    match :*, "/*path", CatchController, :capture
  end
end
