use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.

config :perseids, Perseids.Endpoint,
  http: [port: 4000],
  code_reloader: true,
  debug_errors: true
  # check_origin: false,
  # watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    # cd: Path.expand("../", __DIR__)]]


# Watch static and templates for browser reloading.
# config :perseids, Perseids.Endpoint,
#   live_reload: [
#     patterns: [
#       ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
#       ~r{priv/gettext/.*(po)$},
#       ~r{web/views/.*(ex)$},
#       ~r{web/templates/.*(eex)$}
#     ]
#   ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
# config :logger, level: :info # Do not print debug messages


# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
# config :phoenix, :stacktrace_depth, 20

# Configure your database
config :perseids, :db,
  name: "perseids",
  hostname: "mongo"
# config :perseids, Perseids.Repo,
#   adapter: Mongo.Ecto,
#   database: "perseids_dev",
#   pool_size: 10

config :perseids, :magento,
  magento_api_endpoint: System.get_env("MAGENTO_API_ENDPOINT"),
  admin_username: System.get_env("MAGENTO_ADMIN_USERNAME"),
  admin_password: System.get_env("MAGENTO_ADMIN_PASSWORD")

config :perseids, :get_response,
    api_url: System.get_env("GETRESPONSE_API_URL"),
    api_key: System.get_env("GETRESPONSE_API_KEY"),
    api_campaign_token: System.get_env("GETRESPONSE_API_CAMPAIGN_TOKEN")
