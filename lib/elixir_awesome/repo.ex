defmodule ElixirAwesome.Repo do
  use Ecto.Repo,
    otp_app: :elixir_awesome,
    adapter: Ecto.Adapters.Postgres
end
