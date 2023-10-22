defmodule LiveSelectWeb.Router do
  use LiveSelectWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LiveSelectWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, %{"content-security-policy" => "default-src 'self'"}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiveSelectWeb do
    pipe_through :browser

    live "/", ShowcaseLive
    live "/lc", LiveComponentTest
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveSelectWeb do
  #   pipe_through :api
  # end
end
