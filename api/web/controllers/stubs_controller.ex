defmodule Perseids.StubsController do
  use Perseids.Web, :controller

  def products(conn, _params) do
    render conn, "products.json"
  end

  def product(conn, _params) do
    render conn, "product.json"
  end

  def categories(conn, _params) do
    render conn, "categories.json"
  end
end
