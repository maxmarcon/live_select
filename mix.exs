defmodule LiveSelect.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_select,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: [
        extras: ["README.md"]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {LiveSelect.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix_live_view, "~> 0.17.5"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix, "~> 1.6.10", optional: true},
      {:phoenix_live_reload, "~> 1.2", only: :dev, optional: true},
      {:floki, ">= 0.30.0", only: :test, optional: true},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev, optional: true},
      {:telemetry_metrics, "~> 0.6", optional: true},
      {:telemetry_poller, "~> 1.0", optional: true},
      {:jason, "~> 1.2", optional: true},
      {:plug_cowboy, "~> 2.5"},
      {:faker, "~> 0.17", optional: true},
      {:tailwind, "~> 0.1.6", only: :dev, optional: true},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
