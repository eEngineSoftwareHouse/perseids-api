defmodule Perseids.ProductController do
  use Perseids.Web, :controller

  require Perseids.Pagination

  alias Perseids.Pagination
  alias Perseids.Product

  def index(conn, params) do

    %{"products" => products, "count" => count, "params" => params} = params
    |> Pagination.prepare_params
    |> ORMongo.set_language(conn)
    |> Product.find

    render conn, "index.json", products: products, count: count, params: params
  end


  def show(%{assigns: %{lang: lang}} = conn, %{"source_id" => source_id}) do
    render conn, "product.json", product: Product.find_one(source_id: source_id, lang: lang)
  end

  def check_stock(conn, %{"sku" => sku}) do
    case Magento.product_stock(sku) do
      {:ok, stock} -> json(conn, stock)
      {:error, reason} -> json(conn, %{errors: [reason]})
      _ -> json(conn, %{errors: ["Wystąpił błąd"]})
    end
  end

  def check_stock(conn, %{"sku_list" => sku_list}) do
    json(conn, Magento.stock_items(sku_list))
  end

end
