defmodule Perseids.Endpoint do
  use Phoenix.Endpoint, otp_app: :perseids
  # Serve at "/" the static files from "priv/static" directory.
  
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "images/uploads/", 
    from: "/webapps/perseids/assets/images/", 
    gzip: false
  
  plug Plug.Static,
    # "at" must be the same as scope defined in router to work properly on production setup
    at: "api/v1/", 
    from: "/webapps/perseids/priv/static/", 
    gzip: false    

  plug Plug.RequestId
  plug Plug.Logger


  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, Perseids.Parsers.JSON],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  # plug Plug.Session,
  #   store: :cookie,
  #   key: "_perseids_key",
  #   signing_salt: "r9hltRP2"

  plug Perseids.Router
end
