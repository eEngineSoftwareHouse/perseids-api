defmodule Perseids.ProductController do
  use Perseids.Web, :controller

  require Perseids.Pagination

  alias Perseids.Pagination
  alias Perseids.Product

  def index(conn, params) do
    %{"products" => products, "count" => count, "params" => params} = params
    |> Pagination.prepare_params
    |> ORMongo.set_language(conn)
    |> Product.find(conn.assigns[:group_id])

    render conn, "index.json", products: products, count: count, params: params
  end

  def show(%{assigns: %{lang: lang}} = conn, params) do
    render conn, "product.json", product: maybe_slug_or_id(params, lang, conn)
  end

  def check_stock(conn, %{"sku" => sku}) do
    case conn.assigns[:store_view] |> Magento.product_stock(sku) do
      {:ok, stock} -> json(conn, stock)
      {:error, reason} -> json(conn, %{errors: [reason]})
      _ -> json(conn, %{errors: ["Wystąpił błąd"]})
    end
  end

  def check_stock(conn, %{"sku_list" => sku_list}) do
    json(conn, conn.assigns[:store_view] |> Magento.stock_items(sku_list))
  end

  defp maybe_slug_or_id(%{"url_key" => url_key}, lang, conn) do
    case Product.find_one(conn.assigns[:group_id], url_key: url_key, lang: lang) do
      nil -> maybe_slug_or_id(%{"source_id" => url_key}, lang, conn)
      product -> product
    end
  end

  defp maybe_slug_or_id(%{"source_id" => source_id}, lang, conn), do: Product.find_one(conn.assigns[:group_id], source_id: source_id, lang: lang)
  
end
