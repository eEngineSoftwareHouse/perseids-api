# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :perseids,
  ecto_repos: []

# Configures the endpoint
config :perseids, Perseids.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7m/fcLNBZQlSrbrKk3+bcT8t75UfDEerlhzw7odrTQl0IO6w9am5MjBpncbPMsj9",
  render_errors: [view: Perseids.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Perseids.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure phoenix generators
config :phoenix, :generators,
  binary_id: true,
  migration: false,
  sample_binary_id: "111111111111111111111111"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
