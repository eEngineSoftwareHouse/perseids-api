use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :perseids, Perseids.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :perseids, :db, name: "perseids_test"
# config :perseids, Perseids.Repo,
#   adapter: Mongo.Ecto,
#   database: "perseids_test",
#   pool_size: 1
