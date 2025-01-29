# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :live_select, :start_application, true

config :live_select, :change_event_handler, LiveSelect.ChangeEventHandler

# Configures the endpoint
config :live_select, LiveSelectWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: LiveSelectWeb.ErrorHTML, json: LiveSelectWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LiveSelect.PubSub,
  live_view: [signing_salt: "yxyt7t35"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  package: [
    args:
      ~w(js/live_select.js --target=es2017 --minify --outfile=../priv/static/live_select.min.js),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.3.3",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :mix, colors: [enabled: true]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
