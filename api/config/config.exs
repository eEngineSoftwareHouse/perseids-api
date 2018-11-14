# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Rollbar
config :rollbax,
  access_token: System.get_env("ROLLBAR_TOKEN"),
  environment: "production"

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

# Configure Magento Access
config :perseids, :magento,
  magento_api_endpoint:   System.get_env("MAGENTO_API_ENDPOINT"),
  admin_username:         System.get_env("MAGENTO_ADMIN_USERNAME"),
  admin_password:         System.get_env("MAGENTO_ADMIN_PASSWORD"),
  default_category_id:    System.get_env("MAGENTO_DEFAULT_CATEGORY_ID")

# Configure FreshMail
config :perseids, :fresh_mail,
  api_url: System.get_env("FRESHMAIL_API_URL"),
  api_key: System.get_env("FRESHMAIL_API_KEY"),
  api_secret: System.get_env("FRESHMAIL_API_SECRET"),
  api_list_token_pl: System.get_env("FRESHMAIL_API_LIST_TOKEN_PL"),
  api_list_token_en: System.get_env("FRESHMAIL_API_LIST_TOKEN_EN")

# Configure PayU
config :perseids, :payu_pln,
  api_url:        System.get_env("PAYU_API_URL"),
  notify_url:     System.get_env("PAYU_NOTIFY_URL"),
  continue_url:   System.get_env("PAYU_CONTINUE_URL"),
  pos_id:         System.get_env("PLN_PAYU_POS_ID"),
  client_id:      System.get_env("PLN_PAYU_CLIENT_ID"),
  client_secret:  System.get_env("PLN_PAYU_CLIENT_SECRET"),
  second_key:     System.get_env("PLN_PAYU_SECOND_KEY")

config :perseids, :payu_eur,
  api_url:        System.get_env("PAYU_API_URL"),
  notify_url:     System.get_env("PAYU_NOTIFY_URL"),
  continue_url:   System.get_env("PAYU_CONTINUE_URL"),
  pos_id:         System.get_env("EUR_PAYU_POS_ID"),
  client_id:      System.get_env("EUR_PAYU_CLIENT_ID"),
  client_secret:  System.get_env("EUR_PAYU_CLIENT_SECRET"),
  second_key:     System.get_env("EUR_PAYU_SECOND_KEY")  

config :perseids, :payu_gbp,
  api_url:        System.get_env("PAYU_API_URL"),
  notify_url:     System.get_env("PAYU_NOTIFY_URL"),
  continue_url:   System.get_env("PAYU_CONTINUE_URL"),
  pos_id:         System.get_env("GBP_PAYU_POS_ID"),
  client_id:      System.get_env("GBP_PAYU_CLIENT_ID"),
  client_secret:  System.get_env("GBP_PAYU_CLIENT_SECRET"),
  second_key:     System.get_env("GBP_PAYU_SECOND_KEY")

config :perseids, :payu_usd,
  api_url:        System.get_env("PAYU_API_URL"),
  notify_url:     System.get_env("PAYU_NOTIFY_URL"),
  continue_url:   System.get_env("PAYU_CONTINUE_URL"),
  pos_id:         System.get_env("USD_PAYU_POS_ID"),
  client_id:      System.get_env("USD_PAYU_CLIENT_ID"),
  client_secret:  System.get_env("USD_PAYU_CLIENT_SECRET"),
  second_key:     System.get_env("USD_PAYU_SECOND_KEY")


# Configure PayPal
config :perseids, :paypal,
  api_url:       System.get_env("PAYPAL_API_URL"),
  client_id:     System.get_env("PAYPAL_CLIENT_ID"),
  client_secret: System.get_env("PAYPAL_CLIENT_SECRET"),
  return_url:    System.get_env("PAYPAL_RETURN_URL"),
  cancel_url:    System.get_env("PAYPAL_CANCEL_URL")

# Configure ING
config :perseids, :ing,
  api_url:           System.get_env("ING_API_URL"),
  client_id:         System.get_env("ING_CLIENT_ID"),
  service_id:        System.get_env("ING_SERVICE_ID"),
  service_key:       System.get_env("ING_SERVICE_KEY"),
  return_url:        System.get_env("ING_RETURN_URL"),
  cancel_url:        System.get_env("ING_CANCEL_URL"),
  twisto_public_key: System.get_env("ING_TWISTO_PUBLIC_KEY"),
  twisto_secret_key: System.get_env("ING_TWISTO_SECRET_KEY")

config :perseids, :micro_admin,
  base_url: System.get_env("MICRO_ADMIN_BASE_URL"),
  jwt_auth_user: System.get_env("MICRO_ADMIN_JWT_AUTH_USER"),
  jwt_auth_pass: System.get_env("MICRO_ADMIN_JWT_AUTH_PASS")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
