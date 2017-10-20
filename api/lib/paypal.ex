defmodule PayPal do
  @paypal_api_url Application.get_env(:perseids, :paypal)[:api_url]
  @paypal_client_id Application.get_env(:perseids, :paypal)[:client_id]
  @paypal_client_secret Application.get_env(:perseids, :paypal)[:client_secret]
  @paypal_return_url Application.get_env(:perseids, :paypal)[:return_url]
  @paypal_cancel_url Application.get_env(:perseids, :paypal)[:cancel_url]
  @paypal_timeout [connect_timeout: 30000, recv_timeout: 30000, timeout: 30000]

  def create_payment(%{"products" => products, "shipping" => shipping, "lang" => lang} = order) do
    shipping = Perseids.Shipping.find_one(source_id: shipping, lang: lang)

    payment_info = %{
      "intent" => "sale",
      "redirect_urls" => %{
        "return_url" => @paypal_return_url,
        "cancel_url" => @paypal_cancel_url
      },
      "payer" => %{
        "payment_method" => "paypal"
      },
      "transactions" => [
        %{
          "amount" => %{
            "total" => calc_order_total(products, shipping, lang),
            "currency" => "PLN" # tak jak w PayU czeka na obsługę walut
          },
          "custom" => BSON.ObjectId.encode!(order["_id"])
        }
      ]
    }

    case post("payments/payment", payment_info) do
      {:ok, response} -> manage_response(response, order)
      {:error, message} -> raise "PayPal payment request error: #{message}"
    end
  end

  def execute_payment(payment_id, payer_id) do
    order = Perseids.Order.find(filter: %{"payment_id" => [payment_id]}) |> List.first
    case HTTPoison.post(order["execute_url"], Poison.encode!(%{ "payer_id" => payer_id }), [{"Content-Type", "application/json"}, {"Authorization", "Bearer #{token()}"}]) do
      {:ok, response} -> update_order(response, payment_id)
      {:error, message} -> {:error, "PayPal order request error: #{message}"}
    end
  end


  defp update_order(%{body: body} = _payment, payment_id) do
    case Poison.decode!(body) do
     %{"state" => "approved"} -> {:ok, ORMongo.update_one("orders", %{"payment_id" => payment_id}, %{"payment_status" => "COMPLETED"})}
     %{"message" => message} -> {:error, message}
     _ -> {:error, "Payment state or message not found in PayPal request"}
    end
  end

  defp manage_response(response, order) do
    %{"links" => links, "id" => payment_id} = case response.status_code do
      201 -> Poison.decode!(response.body)
      status -> raise "PayPal payment returned #{status}"
    end

    links = links
    |> Enum.reduce(%{}, fn(elem, acc) -> Map.put_new(acc, elem["rel"], elem["href"]) end)

    case ORMongo.update_one("orders", %{"_id" => order["_id"]}, %{"redirect_url" => links["approval_url"], "execute_url" => links["execute"], "payment_id" => payment_id}) do
      {:ok, _update_result} -> order |> Map.put_new("redirect_url", links["approval_url"])
      _ -> order
    end
  end

  defp calc_order_total(products, shipping, lang) do
    products
    |> Enum.map(&get_product_price(&1, lang) * &1["count"])
    |> payu_products_price_sum
    |> Kernel.+(get_shipping_price(shipping))
  end

  defp get_shipping_price(shipping) do
    shipping["price"]
    |> payu_format_price
  end

  defp get_product_price(product, lang) do
    Perseids.Product.find_one(source_id: product["id"], lang: lang)["price"]
    |> List.first
  end

  defp payu_products_price_sum(prices_list) do
    prices_list
    |> Enum.sum
    |> payu_format_price
  end

  defp payu_format_price(price) do
    price
    |> Kernel./(1) # be sure that price is INT
    |> Float.round(2)
  end

  defp oauth_token() do
    auth = [basic_auth: {@paypal_client_id, @paypal_client_secret}]
    body = "grant_type=client_credentials"
    case HTTPoison.post(@paypal_api_url <> "oauth2/token", body, [{"Content-Type", "application/x-www-form-urlencoded"}], @paypal_timeout ++ [hackney: auth]) do
      { :ok, response } -> paypal_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  defp paypal_response(response) do
    case response.status_code do
      200 -> { :ok, Poison.decode!(response.body) }
      _ -> { :error, response.body |> Poison.decode! |> Map.get("error_description") }
    end
  end

  defp post(url, params, headers \\ [], options \\ []) do
    HTTPoison.post(
      @paypal_api_url <> url,
      Poison.encode!(params),
      [{"Content-Type", "application/json"}, {"Authorization", "Bearer #{token()}"} | headers],
      @paypal_timeout ++ options
    )
  end

  defp token({:ok, token} = _params) do
    token["access_token"]
  end

  defp token({:error, _message} = _params) do
    ""
  end

  defp token() do
    oauth_token()
    |> token()
  end
end
