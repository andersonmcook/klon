defmodule Klon.MixProject do
  use Mix.Project

  def project do
    [
      app: :klon,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: ~w(dev test)a, runtime: false},
      {:dialyxir, "~> 1.4", only: ~w(dev test)a, runtime: false},
      {:ecto, "~> 3.12"},
      {:ecto_sql, "~> 3.12", only: ~w(dev test)a},
      {:ex_doc, "~> 0.37", only: ~w(dev test)a, runtime: false},
      {:postgrex, "~> 0.20", only: ~w(dev test)a, optional: true}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp aliases do
    ["ecto.reset": ["ecto.drop --quiet", "ecto.create --quiet", "ecto.migrate --quiet"]]
  end
end
