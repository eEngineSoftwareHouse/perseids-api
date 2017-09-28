defmodule Perseids.PaymentController do
  use Perseids.Web, :controller
  alias Perseids.Order

  def notify(conn, %{"order" => %{"extOrderId" => order_id, "status" => status}} = _params) do
    order_id |> Order.update(%{"payment_status" => status})
    json(conn, "ok")
  end
end
