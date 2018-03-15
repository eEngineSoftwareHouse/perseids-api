defmodule Perseids.PaymentController do
  use Perseids.Web, :controller
  alias Perseids.Order

  def payu_notify(conn, %{"order" => %{"extOrderId" => order_id, "status" => status, "currencyCode" => currency}} = params) do
    %{"signature" => signature} = Regex.named_captures(~r/signature=(?<signature>.{32})/, conn |> get_req_header("openpayu-signature") |> List.first)

    PayU.check_sig(currency, conn.private.raw_body, signature)
    |> maybe_success(order_id, status, conn)
  end

  def paypal_accept(conn, %{"PayerID" => payer_id, "paymentId" => payment_id} = _params) do
    case PayPal.execute_payment(payment_id, payer_id) do
      {:ok, _saved} -> json(conn, "ok")
      {:error, message} ->
        conn
        |> put_status(422)
        |> json(%{errors: [message]})
    end
  end

  def paypal_cancel(conn, _params) do
    json(conn, "ok")
  end

  defp maybe_success(true, order_id, status, conn) do
    order_id |> Order.update(%{"payment_status" => status})
    json(conn, "ok")
  end

  defp maybe_success(false, _order_id, _status, conn) do
    conn
    |> put_status(422)
    |> json(%{errors: "SIG don't match"})
  end
end
