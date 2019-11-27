use Mix.Config

# Configure your database
config :elixir_awesome, ElixirAwesome.Repo,
  username: "postgres",
  password: "postgres",
  database: "elixir_awesome_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :elixir_awesome, ElixirAwesomeWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
