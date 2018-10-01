defmodule Perseids.PaymentController do
  use Perseids.Web, :controller
  alias Perseids.Order

  def payu_notify(conn, %{"order" => %{"extOrderId" => order_id, "status" => status, "currencyCode" => currency}} = _params) do
    %{"signature" => signature} = Regex.named_captures(~r/signature=(?<signature>.{32})/, conn |> get_req_header("openpayu-signature") |> List.first)

    PayU.check_sig(currency, conn.private.raw_body, signature)
    |> maybe_success(order_id, status, conn)
  end

  def payu_notify(conn, %{"extOrderId" => order_id, "refund" => %{"status" => "FINALIZED"}}) do
    with false <- order_id |> Order.find_one |> is_nil,
      { :ok, _ } <- Order.update(order_id, %{ "payment_status" => "REFUND" }) 
    do
      json(conn, "ok")
    else
      true -> conn |> put_status(404) |> json(%{ errors: "Not Found" })
      _   -> conn |> put_status(422) |> json(%{ errors: "Unprocessable Entity" })
    end  
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

  def ing_notify(conn, %{"transaction" => %{"orderId" => order_id, "status" => status}} = _params) do
    %{"signature" => signature} = Regex.named_captures(~r/signature=(?<signature>.{64})/, conn |> get_req_header("x-imoje-signature") |> List.first)
    
    ING.check_sig(conn.private.raw_body, signature)
    |> maybe_success(order_id, status, conn)
  end

  def ing_twisto(conn, %{"order_id" => order_id}) do
    twisto_base64 = 
      order_id 
      |> Order.find_one
      |> ING.transfer_struct_to_twisto

    case twisto_base64 do
      nil -> conn |> put_status(404) |> json(%{ errors: "Not Found" })
      twisto_base64 -> conn |> json(twisto_base64)
    end
  end

  defp maybe_success(true, order_id, "settled", conn) do
    order_id |> Order.update(%{"payment_status" => "COMPLETED"})
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
