import Config

config :klon,
  ecto_repos: [Klon.Repo]

config :klon, Klon.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/support",
  url: "postgres://localhost:5432/klon_test"

config :logger, level: :warning
