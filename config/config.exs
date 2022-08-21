# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :live_select, :start_application, true

# Configures the endpoint
config :live_select, LiveSelectWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: LiveSelectWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: LiveSelect.PubSub,
  live_view: [signing_salt: "yxyt7t35"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :mix, colors: [enabled: true]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
