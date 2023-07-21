defmodule LiveSelect.MixProject do
  use Mix.Project

  def project do
    [
      app: app(),
      version: "1.1.1",
      elixir: "~> 1.13",
      description: "Dynamic (multi)selection field for LiveView",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      package: package(),
      source_url: "https://github.com/maxmarcon/live_select",
      name: "LiveSelect"
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    if Application.get_env(app(), :start_application) do
      [
        mod: {LiveSelect.Application, []},
        extra_applications: [:logger, :runtime_tools]
      ]
    else
      []
    end
  end

  defp app(), do: :live_select

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]

  defp elixirc_paths(:prod) do
    # so we do not compile web stuff when used as dependency
    ["lib/live_select", "lib/live_select.ex"]
  end

  defp elixirc_paths(_) do
    ["lib"]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix_live_view, "~> 0.19"},
      {:phoenix_html, "~> 3.3"},
      {:jason, "~> 1.0"},
      {:phoenix, ">= 1.6.0", optional: true},
      {:phoenix_view, "~> 2.0", optional: true},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_ecto, "~> 4.0", only: [:dev, :test, :demo]},
      {:ecto, "~> 3.8", only: [:dev, :test, :demo]},
      {:floki, ">= 0.30.0", only: :test},
      {:esbuild, "~> 0.4", only: [:dev, :test, :demo]},
      {:plug_cowboy, "~> 2.5", only: [:dev, :demo]},
      {:faker, "~> 0.17", only: [:dev, :test]},
      {:tailwind, "~> 0.2", only: [:dev, :test, :demo]},
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
      setup: ["deps.get", "cmd --cd assets yarn"],
      "assets.package": ["esbuild package"],
      "assets.deploy": [
        "cmd --cd assets yarnpkg",
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/maxmarcon/live_select"
      },
      files: ~w(mix.exs lib/live_select** package.json priv/static/live_select.min.js)
    ]
  end

  defp docs() do
    [
      main: "readme",
      extras: [
        "README.md": [title: "Readme"],
        "styling.md": [],
        "cheatsheet.cheatmd": [title: "Cheatsheet"],
        "CHANGELOG.md": []
      ],
      filter_modules: ~r/LiveSelect($|\.)/,
      groups_for_functions: [
        Components: &(&1[:type] == :component)
      ]
    ]
  end
end
