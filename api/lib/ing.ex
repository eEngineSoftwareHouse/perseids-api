defmodule ING do
  @ing_api_url Application.get_env(:perseids, :ing)[:api_url]
  @ing_client_id Application.get_env(:perseids, :ing)[:client_id]
  @ing_service_id Application.get_env(:perseids, :ing)[:service_id]
  @ing_service_key Application.get_env(:perseids, :ing)[:service_key]
  @ing_return_url Application.get_env(:perseids, :ing)[:return_url]
  @ing_cancel_url Application.get_env(:perseids, :ing)[:cancel_url]
  @ing_timeout [connect_timeout: 30000, recv_timeout: 30000, timeout: 30000]

  def create_payment(%{"currency" => currency, "order_total_price" => order_total_price} = order) do
    payment_info = %{
      "merchantId" => @ing_client_id,
      "serviceId" => @ing_service_id,
      "amount" => ing_price(order_total_price),
      "currency" => currency,
      "orderId" => BSON.ObjectId.encode!(order["_id"]),
      "orderDescription" => "Zamówienie " <> BSON.ObjectId.encode!(order["_id"]) <> " - pl.manymornings.com",
      "customerFirstName" => "Pan/i",
      "customerLastName" => order["address"]["shipping"]["name"],
      "customerEmail" => order["email"],
      "customerPhone" => order["address"]["shipping"]["phone-number"],
      "urlSuccess" => @ing_return_url,
      "urlFailure" => @ing_cancel_url,
      "urlReturn" => @ing_return_url
    }
    signature = payment_info |> create_signature
    struct = payment_info |> Map.merge(%{ "signature" => signature }) |> URI.encode_query
    case post("payment", struct) do
      {:ok, response} -> manage_response(response, order)
      {:error, message} -> raise "ing payment request error: #{message}"
    end
  end

  def check_sig(body, signature) do
    :crypto.hash(:sha256, body <> @ing_service_key)
    |> Base.encode16(case: :lower)
    |> Kernel.==(signature)
  end

  defp manage_response(response, order) do
    redirect_url = case response do
      %HTTPoison.Response{body: _, headers: headers, status_code: 302 } -> headers |> Enum.into(%{}) |> Map.get("Location")
      _ -> raise "ING order response error"
    end

    case ORMongo.update_one("orders", %{"_id" => order["_id"]}, %{"redirect_url" => redirect_url}) do
      {:ok, _update_result} -> order |> Map.put_new("redirect_url", redirect_url)
      _ -> order
    end
  end

  defp post(url, params) do
    HTTPoison.post(@ing_api_url <> url, params, [{"Content-Type", "application/x-www-form-urlencoded"}], @ing_timeout)
  end

  defp create_signature(payment_info) do
    body = 
      payment_info
      |> Enum.sort
      |> Enum.map(fn ({key, value})-> "#{key}=#{value}&" end) 
      |> Enum.join
    
    hash =
      :crypto.hash(:sha256, body <> @ing_service_key)
      |> Base.encode16(case: :lower)

    hash <> ";sha256"
  end

  defp ing_price(price) do
    price
    |> Kernel./(1) # be sure that price is INT
    |> Float.round(2)
    |> Kernel.*(100) # PayU need price in 0,01
    |> round
  end
end