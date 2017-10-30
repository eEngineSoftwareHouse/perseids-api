defmodule Perseids.Router do
  use Perseids.Web, :router

  alias Perseids.Plugs.Language
  alias Perseids.Plugs.CurrentUser
  alias Perseids.Plugs.Session

  pipeline :api do
    plug Corsica, origins: "*", allow_headers: ~w(content-type authorization Client-Language accept origin)
    plug :accepts, ["json"]
    plug Language
    plug CurrentUser
    if Mix.env == :dev do
      plug Phoenix.CodeReloader
    end
  end

  pipeline :authorized do
    plug Session
  end

  scope "/api/v2" do
    forward "/", Absinthe.Plug,
      schema: Perseids.Schema
  end

  forward "/graphiql", Absinthe.Plug.GraphiQL,
    schema: Perseids.Schema

  scope "/", Perseids do
    get "/robots.txt",  StatusController, :robots
  end

  scope "/api/v1", Perseids do
    pipe_through :api

    options "/*path", SessionController, :options

    get "/status/magento", StatusController, :magento

    get "/products", ProductController, :index
    get "/products/search", ProductController, :index
    get "/products/stock/:sku", ProductController, :check_stock
    get "/products/stock", ProductController, :check_stock
    get "/product/:url_key", ProductController, :show

    get "/params", ParamController, :index
    get "/params/:code", ParamController, :show

    get "/categories", CategoryController, :index
    get "/category/:source_id", CategoryController, :show

    get "/lookbooks", LookbookController, :index
    get "/lookbook/:source_id", LookbookController, :show

    get "/thresholds", ThresholdController, :index
    get "/threshold/:source_id", ThresholdController, :show

    get "/pages", PageController, :index
    get "/pages/:slug", PageController, :show

    get "/order/delivery_options", OrderController, :delivery_options
    post "/order/create", OrderController, :create

    post "/sessions/create", SessionController, :create
    post "/sessions/destroy", SessionController, :destroy

    post "/account/create", CustomerController, :create

    post "/service/newsletter", ServiceController, :newsletter

    post "/payu_notify", PaymentController, :payu_notify
    get "/paypal_accept", PaymentController, :paypal_accept
    get "/paypal_cancel", PaymentController, :paypal_cancel

    post "/contact", ContactController, :contact_form
  end

  scope "/api/v1", Perseids do
    pipe_through :api
    pipe_through :authorized

    get "/account", CustomerController, :info
    get "/account/address/:address_type", CustomerController, :address
    get "/account/orders", OrderController, :index
    post "/account/update", CustomerController, :update
  end

  scope "/api/stubs", Perseids do
    pipe_through :api
    get "/status/magento", StatusController, :magento

    get "/products", StubsController, :products
    get "/product/", StubsController, :product

    get "/categories", StubsController, :categories
  end
end
