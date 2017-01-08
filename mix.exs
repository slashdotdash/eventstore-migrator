defmodule EventStore.Migrator.Mixfile do
  use Mix.Project

  def project do
    [
      app: :eventstore_migrator,
      version: "0.1.0",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      description: description(),
      package: package(),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:eventstore, "~> 0.7"},
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:poison, "~> 3.0", only: [:test]},
      {:postgrex, "~> 0.13"},
      {:uuid, "~> 1.1", only: :test}
    ]
  end

  defp description do
"""
Copy & transformation migration strategy for EventStore.
"""
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Ben Smith"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/slashdotdash/eventstore-migrator",
               "Docs" => "https://hexdocs.pm/eventstore-migrator/"}
    ]
  end
end
