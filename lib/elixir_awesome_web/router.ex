defmodule ElixirAwesomeWeb.Router do
  use ElixirAwesomeWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", ElixirAwesomeWeb do
    pipe_through :browser

    get "/", ProjectController, :index
  end
end
