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

config :rollbax, enabled: :log


# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
# config :phoenix, :stacktrace_depth, 20

# Configure your database
config :perseids, :db,
  name: "perseids",
  hostname: "mongo"

# Mailer config
config :perseids, Perseids.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "smtp.emaillabs.net.pl",
  port: 587,
  username: System.get_env("SMTP_USERNAME"),
  password: System.get_env("SMTP_PASSWORD"),
  tls: :if_available, # can be `:always` or `:never`
  ssl: false, # can be `true`
  retries: 1

# Contact form config
config :perseids, :contact_form,
  email: System.get_env("CONTACT_FORM_EMAIL")
