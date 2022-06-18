import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :live_select, LiveSelectWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "hTnE+M7j7UmlMhdUlCMbqCazLpqij0DnurlfNdhxKTbfaA6C/OHHy09E1hSItIM2",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
