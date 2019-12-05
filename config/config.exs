# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :elixir_awesome,
  ecto_repos: [ElixirAwesome.Repo]

config :elixir_awesome,
  autostart: false,
  parse_url:
    "https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md",
  github_api: "https://api.github.com/repos",
  github_login: System.get_env("GITHUB_LOGIN"),
  github_pass: System.get_env("GITHUB_PASS"),
  mod_times_file: "priv/mod_times"

# Configures the endpoint
config :elixir_awesome, ElixirAwesomeWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base:
    "lVTLvW1EN6u2Oe0hreeQT1AdQJR8oDTLOIkdY+uSzzRwOfqCqrTlxr2H0Zq7fHEp",
  render_errors: [
    view: ElixirAwesomeWeb.ErrorView,
    accepts: ~w(html json)
  ],
  pubsub: [name: ElixirAwesome.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
