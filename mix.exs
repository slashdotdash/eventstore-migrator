defmodule EventStore.Migrator.Mixfile do
  use Mix.Project

  def project do
    [
      app: :eventstore_migrator,
      version: "0.1.0",
      elixir: "~> 1.4",
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

  defp deps do
    [
      {:eventstore, "~> 0.7"},
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:postgrex, "~> 0.13"},
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
