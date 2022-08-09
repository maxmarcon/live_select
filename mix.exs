defmodule LiveSelect.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_select,
      version: "0.1.0",
      elixir: "~> 1.13",
      description: "Dynamic search and selection input field for LiveView",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: [
        extras: ["README.md", "CHANGELOG.md"],
        filter_modules: "LiveSelect$",
        assets: "priv/static/images"
      ],
      package: package(),
      source_url: "https://github.com/maxmarcon/live_select"
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
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:floki, ">= 0.30.0", only: :test},
      {:esbuild, "~> 0.4", only: :dev},
      {:telemetry_metrics, "~> 0.6", only: :dev},
      {:telemetry_poller, "~> 1.0", only: [:dev, :test]},
      {:jason, "~> 1.2", only: [:dev, :test]},
      {:plug_cowboy, "~> 2.5", only: :dev},
      {:faker, "~> 0.17", only: [:dev, :test]},
      {:tailwind, "~> 0.1.6", only: :dev},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.0", only: :test}
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
      "assets.deploy": ["esbuild module"]
    ]
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/maxmarcon/live_select"
      },
      files:
        ~w(lib/live_select/component.* lib/live_select.ex package.json priv/static/live_select.min.js)
    ]
  end
end
