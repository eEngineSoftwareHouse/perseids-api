use Mix.Config

config :perseids, Perseids.Endpoint,
  http: [port: 4000]

config :logger, level: :warn

config :perseids, :db,
  name: "perseids",
  hostname: "mongo"

config :perseids, :magento,
  admin_username: System.get_env("MAGENTO_ADMIN_USERNAME"),
  admin_password: System.get_env("MAGENTO_ADMIN_PASSWORD")

config :perseids, :get_response,
    api_url: System.get_env("GETRESPONSE_API_URL"),
    api_key: System.get_env("GETRESPONSE_API_KEY"),
    api_campaign_token: System.get_env("GETRESPONSE_API_CAMPAIGN_TOKEN")

config :perseids, :payu,
    api_url: System.get_env("PAYU_API_URL"),
    pos_id: System.get_env("PAYU_POS_ID"),
    client_id: System.get_env("PAYU_CLIENT_ID"),
    client_secret: System.get_env("PAYU_CLIENT_SECRET")
