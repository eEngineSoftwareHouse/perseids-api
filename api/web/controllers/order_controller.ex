defmodule Perseids.OrderController do
  use Perseids.Web, :controller
  require Perseids.Pagination
  alias Perseids.Pagination
  alias Perseids.Order
  alias Perseids.Discount
  alias Perseids.Product

  # action_fallback Perseids.FallbackController

  def index(conn, params) do
    orders = Order.find(filter: %{"customer_id" => [conn.assigns.customer_id]})

    conn |> render_orders(orders, params)
  end

  def check_orders(conn, %{"id" => object_id} = _params) do
    orders = Order.find( query: %{ "id" => object_id} )
    |> Enum.filter(fn(elem) -> !Map.has_key?(elem, "synchronized") end)
    
    render conn, "orders.json", orders: orders, count: orders |> Enum.count
  end

  def check_orders(conn, params) do
    orders = Order.find(
      query: %{
        "synchronized" => %{"$ne" => 1},
        # "$and" => params |> Map.drop(["sort"]) |> Map.to_list |> Enum.map(fn({k, v}) -> %{k => v} end)
        "$and" => maybe_all(params)
      }, 
      options: %{
        "sort" => %{
          "created_at" => (params["sort"] || "-1") |> String.to_integer
        }
      }
    )
    |> Enum.sort(&(&1["created_at"] > &2["created_at"]))

    render conn, "orders.json", orders: orders, count: orders |> Enum.count
  end

  def maybe_all(params) when params == %{}, do: [ %{ "_id" => %{ "$exists" => true } } ]
  def maybe_all(params), do: params |> Map.drop(["sort"]) |> Map.to_list |> Enum.map(fn({k, v}) -> %{k => v} end)

  def wholesale_create(conn, params), do: conn |> create(params)

  def create(conn, params) do
    changeset = Perseids.Order.changeset(%Perseids.Order{}, prepare_params(conn, params))

    if changeset.valid? do
      order = Order.create(changeset.changes, conn.assigns[:group_id], conn.assigns[:tax_rate])
      
      order["products"]
      |> Enum.each(&(Product.product_qty_update(&1, conn.assigns.lang)))

      render conn, "order.json", order: order
    else
      conn
      |> put_status(422)
      |> render("errors.json", changeset: changeset)
    end
  end

  def discount(conn, %{"code" => _code} = params) do
    discount = Helpers.to_keyword_list(params)
    |> ORMongo.set_language(conn)
    |> Discount.find_one

    case discount do
      nil ->
        conn
        |> put_status(422)
        |> json(%{errors: [gettext "There's no such code"]})
      code -> json(conn, %{value: code["value"], type: code["type"]})
    end
  end

  # fallback for non-authorized wholesale shippings, to be removed after proper production update
  def delivery_options(conn, %{"country" => _country, "wholesale" => "true", "count" => _count} = params),  do: wholesale_delivery_options(conn, params)
  def delivery_options(conn, %{"country" => country}) do
    render conn, "index.json", Order.delivery_options([where: [%{ "country" => country, "wholesale" => false }], lang: conn.assigns[:lang]])
  end
  def delivery_options(conn, %{}) do
    json(conn, Order.get_countries([query: %{"wholesale" => false}, lang: conn.assigns[:lang], options: %{"$orderby" => %{"country_full" => 1}}]))
  end

  def wholesale_delivery_options(conn, %{"country" => country, "count" => count}) do
    render conn, "index.json", Order.get_wholesale_shipping_for(country, count |> String.to_integer, conn.assigns[:lang])
  end
  def wholesale_delivery_options(conn, %{}) do
    json(conn, Order.get_countries([where: [%{ "wholesale" => true }], lang: conn.assigns[:lang]]))
  end


  defp prepare_params(conn, params) do
    params
    |> Map.put_new("customer_id", conn.assigns[:customer_id])
    |> Map.put_new("lang", conn.assigns.lang)
    |> Map.put_new("currency", conn.assigns.currency)
    |> Map.put_new("wholesale", conn.assigns[:wholesale])
    |> Map.put_new("group_id", conn.assigns[:group_id])
    |> Map.put_new("tax_rate", conn.assigns[:tax_rate])
  end

  defp render_orders(conn, orders, params) do
    orders_count = orders |> Enum.count
    orders = orders |> Pagination.paginate_collection(params)

    render conn, "orders.json", orders: orders, count: orders_count, page_size: orders.page_size
  end

  def update_order(conn, %{ "id" => id } = _params) do
    case id |> Order.update(%{"payment_code" => "banktransfer", "payment" => "banktransfer-pre", "payment_name" => "Przelew", "manually_changed" => true}, true) do
      { :ok, _response } -> conn |> json(:ok)
      { :error, message } -> conn |> put_status(404) |> json(%{ errors: message })
    end
  end
end
