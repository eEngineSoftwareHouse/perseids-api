defmodule PayU do
  @payu_api_version_endpoint "api/v2_1/"
  @payu_timeout [connect_timeout: 30000, recv_timeout: 30000, timeout: 30000]

  def oauth_token(currency) do
    body = "grant_type=client_credentials&client_id=#{payu_config(currency, :client_id)}&client_secret=#{payu_config(currency, :client_secret)}"
    case HTTPoison.post(payu_config(currency, :api_url) <> "pl/standard/user/oauth/authorize", body, [{"Content-Type", "application/x-www-form-urlencoded"}], @payu_timeout) do
      { :ok, response } -> payu_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def check_sig(currency, json_body, signature) do
    :crypto.hash(:md5, json_body <> payu_config(currency, :second_key))
    |> Base.encode16(case: :lower)
    |> Kernel.==(signature)
  end

  def place_order(%{"email" => email, "products" => products, "shipping" => shipping, "lang" => lang, "currency" => currency, "shipping_price" => shipping_price, "order_total_price" => order_total_price} = order) do
    shipping = Perseids.Shipping.find_one(source_id: shipping, lang: lang)
    payu_order = %{
      notifyUrl: payu_config(currency, :notify_url),
      continueUrl: payu_config(currency, :continue_url),
      customerIp: "127.0.0.1", # Needed by PayU, don't know why
      merchantPosId: payu_config(currency, :pos_id),
      description: email <> "-" <> BSON.ObjectId.encode!(order["_id"]),
      currencyCode: currency,
      totalAmount: payu_format_price(order_total_price + shipping_price),
      extOrderId: BSON.ObjectId.encode!(order["_id"]),
      products: order["products"]
      |> Enum.map(&payu_prepare_product(&1, lang))
      |> Kernel.++([shipping |> payu_prepare_shipping(shipping_price)])
    }

    case post(currency, "orders", Poison.encode!(payu_order), [], follow_redirect: true) do
      {:ok, response} -> manage_response(response, order)
      {:error, message} -> IO.inspect message; raise "PayU order request error"
    end
  end

  defp manage_response(response, order) do
    redirect_url = case response.id do
      {:maybe_redirect, 302, headers, _} -> headers |> Enum.into(%{}) |> Map.get("Location")
      _ -> raise "PayU order response error"
    end

    case ORMongo.update_one("orders", %{"_id" => order["_id"]}, %{"redirect_url" => redirect_url}) do
      {:ok, _update_result} -> order |> Map.put_new("redirect_url", redirect_url)
      _ -> order
    end
  end

  defp payu_prepare_shipping(shipping, shipping_price) do
    %{
      name: shipping["name"],
      unitPrice: payu_format_price(shipping_price),
      quantity: 1
    }
  end

  defp payu_prepare_product(product, lang) do
    %{
      name: product["name"],
      unitPrice: get_product_price(product, lang) |> payu_format_price,
      quantity: product["count"]
    }
  end

  defp get_product_price(product, lang) do
    Perseids.Product.find_one(source_id: product["id"], lang: lang)["price"][product["variant_id"]]
  end

  defp payu_format_price(price) do
    price
    |> Kernel./(1) # be sure that price is INT
    |> Float.round(2)
    |> Kernel.*(100) # PayU need price in 0,01
    |> round
  end

  defp payu_response(response) do
    case response.status_code do
      200 -> { :ok, Poison.decode!(response.body) }
      _ -> { :error, response.body |> Poison.decode! |> Map.get("error_description") }
    end
  end

  defp post(currency, url, params, headers, options \\ []) do
    HTTPoison.post(
      payu_config(currency, :api_url) <> @payu_api_version_endpoint <> url,
      params,
      [{"Content-Type", "application/json"}, {"Authorization", "Bearer #{token(currency)}"} | headers],
      @payu_timeout ++ options
    )
  end

  defp token({:ok, token} = _params) do
    token["access_token"]
  end

  defp token({:error, _message} = _params) do
    ""
  end

  defp token(currency) do
    oauth_token(currency)
    |> token()
  end

  defp payu_config("PLN", key), do: Application.get_env(:perseids, :payu_pln)[key]
  defp payu_config("USD", key), do: Application.get_env(:perseids, :payu_usd)[key]
  defp payu_config("EUR", key), do: Application.get_env(:perseids, :payu_eur)[key]
  defp payu_config("GBP", key), do: Application.get_env(:perseids, :payu_gbp)[key]

end
