defmodule Perseids.ProductController do
  use Perseids.Web, :controller

  require Perseids.Pagination

  alias Perseids.Pagination
  alias Perseids.Product

  def index(conn, params) do
    page_size = per_page(params["per_page"])
    %{"products" => products, "count" => count, "params" => params} = params
    |> Pagination.prepare_params
    |> ORMongo.set_language(conn)
    |> Product.find(conn.assigns[:group_id], conn.assigns[:wholesale])
    
    render conn, "index.json", products: products |> change_products_quantity(conn.assigns[:wholesale], -100), count: count, params: params, page_size: page_size |> check_per_page(count)
  end

  def show(%{assigns: %{lang: lang}} = conn, params) do
    case product = maybe_slug_or_id(params, lang, conn) |> change_variants_quantity_by(-10) do
      nil -> conn |> put_status(404) |> json(%{error: gettext "Not found"})
      _ -> render conn, "product.json", product: product
    end
  end

  def check_stock(conn, %{"sku" => sku}) do
    case conn.assigns[:store_view] |> Magento.product_stock(sku) do
      {:ok, stock} -> json(conn, stock)
      {:error, reason} -> 
        conn
        |> put_status(422)
        |> json(%{errors: [reason]})
      _ ->
        conn
        |> put_status(422)
        |> json(%{errors: ["Wystąpił błąd"]})
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

  # OBNIZENIE ILOSCI SZTUK DLA WARIANTÓW [wholesale]
  # Detal dodawanie produktów -> show, hurtownik -> index
  defp change_products_quantity(nil, _wholesale, _count), do: raise "Products load error"
  defp change_products_quantity(products, true, count) do
    products |> Enum.map(&(change_variants_quantity_by(&1, count)))
  end
  defp change_products_quantity(products, wholesale, _count), do: products

  # OBNIZENIE ILOSCI SZTUK DLA WARIANTÓW
  defp change_variants_quantity_by(nil, _count), do: nil
  defp change_variants_quantity_by(product, count) do
    variants = product["variants"] |> Enum.map(&(change_variant_quantity_by(&1, count)))
    product |> Map.put("variants", variants)
  end

  defp change_variant_quantity_by(variant, count) do 
    case variant |> Map.has_key?("quantity") do
      true -> variant |> Map.put("quantity", variant["quantity"] + count)
      false -> variant
    end
  end

  defp per_page(nil), do: 24
  defp per_page(number) when number |> is_binary == true, do: Decimal.new(number) |> Decimal.to_integer
  defp per_page(number), do: number
  defp check_per_page(per_page, count) when per_page > count, do: count
  defp check_per_page(per_page, _count), do: per_page
end
