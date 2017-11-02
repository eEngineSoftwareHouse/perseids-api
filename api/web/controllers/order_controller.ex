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

  def create(conn, params) do
    params = params
    |> Map.put_new("customer_id", conn.assigns[:customer_id])
    |> Map.put_new("lang", conn.assigns.lang)
    |> Map.put_new("currency", conn.assigns.currency)

    changeset = Perseids.Order.changeset(%Perseids.Order{}, params)
    if changeset.valid? do
      render conn, "order.json", order: Order.create(changeset.changes)
    else
      render conn, "errors.json", changeset: changeset
    end
  end

  def delivery_options(conn, %{"country" => country, "wholesale" => "true", "count" => count}) do
    render conn, "index.json", Order.delivery_options([where: [%{ "country" => country, "wholesale" => true }], lang: conn.assigns[:lang]])
  end

  def delivery_options(conn, %{"country" => country}) do
    render conn, "index.json", Order.delivery_options([where: [%{ "country" => country, "wholesale" => false }], lang: conn.assigns[:lang]])
  end
end
