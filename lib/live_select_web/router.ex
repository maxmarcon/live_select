defmodule LiveSelectWeb.Router do
  use LiveSelectWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LiveSelectWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiveSelectWeb do
    pipe_through :browser

    live "/", ShowcaseLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveSelectWeb do
  #   pipe_through :api
  # end
end
