defmodule PayU do
  @payu_api_url Application.get_env(:perseids, :payu)[:api_url]
  @payu_api_version_endpoint "api/v2_1/"
  @payu_pos_id Application.get_env(:perseids, :payu)[:pos_id]
  @payu_notify_url Application.get_env(:perseids, :payu)[:notify_url]
  @payu_continue_url Application.get_env(:perseids, :payu)[:continue_url]
  @payu_second_key Application.get_env(:perseids, :payu)[:second_key]
  @payu_timeout [connect_timeout: 30000, recv_timeout: 30000, timeout: 30000]
  @payu_credentials %{
    grant_type: "client_credentials",
    client_id: Application.get_env(:perseids, :payu)[:client_id],
    client_secret: Application.get_env(:perseids, :payu)[:client_secret]
  }

  def oauth_token do
    body = "grant_type=#{@payu_credentials.grant_type}&client_id=#{@payu_credentials.client_id}&client_secret=#{@payu_credentials.client_secret}"
    case HTTPoison.post(@payu_api_url <> "pl/standard/user/oauth/authorize", body, [{"Content-Type", "application/x-www-form-urlencoded"}], @payu_timeout) do
      { :ok, response } -> payu_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def check_sig(json_body, signature) do
    :crypto.hash(:md5, json_body <> @payu_second_key)
    |> Base.encode16(case: :lower)
    |> Kernel.==(signature)
  end

  def place_order(%{"products" => products, "shipping" => shipping, "lang" => lang, "currency" => currency, "shipping_price" => shipping_price, "order_total_price" => order_total_price} = order) do
    shipping = Perseids.Shipping.find_one(source_id: shipping, lang: lang)

    payu_order = %{
      notifyUrl: @payu_notify_url,
      continueUrl: @payu_continue_url,
      customerIp: "127.0.0.1", # Needed by PayU, don't know why
      merchantPosId: @payu_pos_id,
      description: "ManyMornings.com",
      currencyCode: currency,
      totalAmount: payu_format_price(order_total_price + shipping_price),
      extOrderId: BSON.ObjectId.encode!(order["_id"]),
      products: order["products"]
      |> Enum.map(&payu_prepare_product(&1, lang))
      |> Kernel.++([shipping |> payu_prepare_shipping(shipping_price)])
    }

    case post("orders", Poison.encode!(payu_order), [], follow_redirect: true) do
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

  defp post(url, params, headers, options \\ []) do
    HTTPoison.post(
      @payu_api_url <> @payu_api_version_endpoint <> url,
      params,
      [{"Content-Type", "application/json"}, {"Authorization", "Bearer #{token()}"} | headers],
      @payu_timeout ++ options
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
