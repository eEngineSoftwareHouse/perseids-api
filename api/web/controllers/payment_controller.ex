defmodule Perseids.PaymentController do
  use Perseids.Web, :controller
  alias Perseids.Order


  def payu_notify(conn, %{"order" => %{"extOrderId" => order_id, "status" => status}} = _params) do
    %{"signature" => signature} = Regex.named_captures(~r/signature=(?<signature>.{32})/, conn |> get_req_header("openpayu-signature") |> List.first)

    PayU.check_sig(conn.private.raw_body, signature)
    |> maybe_success(order_id, status, conn)
  end

  def paypal_accept(conn, params) do
    IO.puts "PAYPAL ACCEPT"
    IO.inspect params
    json(conn, "ok")
  end

  def paypal_cancel(conn, params) do
    IO.puts "PAYPAL CANCEL"
    IO.inspect params
    json(conn, "ok")
  end

  defp maybe_success(true, order_id, status, conn) do
    order_id |> Order.update(%{"payment_status" => status})
    json(conn, "ok")
  end

  defp maybe_success(false, _order_id, _status, conn) do
    json(conn, %{errors: "SIG don't match"})
  end
end
