defmodule Perseids.OrderController do
  use Perseids.Web, :controller
  require Perseids.Pagination
  alias Perseids.Pagination
  alias Perseids.Order

  def index(conn, params) do
    orders = Order.find(filter: %{"customer_id" => [conn.assigns.customer_id]})
    orders_count = orders |> Enum.count
    orders = orders |> Pagination.paginate_collection(params)

    render conn, "orders.json", orders: orders, count: orders_count
  end

  def wholesale_create(conn, params), do: conn |> create(params)

  def create(conn, params) do
    changeset = Perseids.Order.changeset(%Perseids.Order{}, prepare_params(conn, params))

    if changeset.valid? do
      render conn, "order.json", order: Order.create(changeset.changes)
    else
      render conn, "errors.json", changeset: changeset
    end
  end

  # fallback for non-authorized wholesale shippings, to be removed after proper production update
  def delivery_options(conn, %{"country" => country, "wholesale" => "true", "count" => count} = params),  do: wholesale_delivery_options(conn, params)

  def wholesale_delivery_options(conn, %{"country" => country, "count" => count}) do
    render conn, "index.json", Order.get_wholesale_shipping_for(country, count |> String.to_integer, conn.assigns[:lang])
  end

  def delivery_options(conn, %{"country" => country}) do
    render conn, "index.json", Order.delivery_options([where: [%{ "country" => country, "wholesale" => false }], lang: conn.assigns[:lang]])
  end

  defp prepare_params(conn, params) do
    params
    |> Map.put_new("customer_id", conn.assigns[:customer_id])
    |> Map.put_new("lang", conn.assigns.lang)
    |> Map.put_new("currency", conn.assigns.currency)
    |> Map.put_new("wholesale", conn.assigns.wholesale)
    |> Map.put_new("group_id", conn.assigns.currency)
  end
end
