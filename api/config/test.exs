use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :perseids, Perseids.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

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
