defmodule PayPal do
  @paypal_api_url Application.get_env(:perseids, :paypal)[:api_url]
  @paypal_client_id Application.get_env(:perseids, :paypal)[:client_id]
  @paypal_client_secret Application.get_env(:perseids, :paypal)[:client_secret]
  @paypal_return_url Application.get_env(:perseids, :paypal)[:return_url]
  @paypal_cancel_url Application.get_env(:perseids, :paypal)[:cancel_url]

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
            "total" => calc_order_total(products, shipping),
            "currency" => "PLN" # tak jak w PayU czeka na obsługę walut
          },
          "custom" => BSON.ObjectId.encode!(order["_id"])
        }
      ]
    }

    case post("payments/payment", payment_info) do
      {:ok, response} -> manage_response(response, order)
      {:error, message} -> raise "PayPal payment request error"
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

  defp calc_order_total(products, shipping) do
    products
    |> Enum.map(&get_product_price(&1) * &1["count"])
    |> payu_products_price_sum
    |> Kernel.+(get_shipping_price(shipping))
  end

  defp get_shipping_price(shipping) do
    shipping["price"]
    |> payu_format_price
  end

  defp get_product_price(product) do
    Perseids.Product.find_one(source_id: product["id"])["price"]
    |> List.first
  end

  defp payu_products_price_sum(prices_list) do
    prices_list
    |> Enum.sum
    |> payu_format_price
  end

  defp payu_format_price(price) do
    price
    |> Float.round(2)
  end

  defp oauth_token() do
    auth = [basic_auth: {@paypal_client_id, @paypal_client_secret}]
    body = "grant_type=client_credentials"
    case HTTPoison.post(@paypal_api_url <> "oauth2/token", body, [{"Content-Type", "application/x-www-form-urlencoded"}], hackney: auth) do
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
    HTTPoison.post(@paypal_api_url <> url, Poison.encode!(params), [{"Content-Type", "application/json"}, {"Authorization", "Bearer #{token()}"} | headers], options)
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
