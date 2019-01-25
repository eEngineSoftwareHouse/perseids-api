defmodule ING do
  @ing_api_url Application.get_env(:perseids, :ing)[:api_url]
  @ing_client_id Application.get_env(:perseids, :ing)[:client_id]
  @ing_service_id Application.get_env(:perseids, :ing)[:service_id]
  @ing_service_key Application.get_env(:perseids, :ing)[:service_key]
  @ing_return_url Application.get_env(:perseids, :ing)[:return_url]
  @ing_cancel_url Application.get_env(:perseids, :ing)[:cancel_url]
  @ing_twisto_secret_key Application.get_env(:perseids, :ing)[:twisto_secret_key]
  @ing_timeout [connect_timeout: 30000, recv_timeout: 30000, timeout: 30000]

  def create_payment(nil, _twisto), do: nil
  def create_payment(order, twisto) do
    payment_info = order |> payment_struct(twisto)
    signature = 
      payment_info 
      |> create_body_params
      |> create_signature

    struct = 
      payment_info 
      |> Map.merge(%{ "signature" => signature }) 
      |> URI.encode_query

    case post("pl/payment", struct) do
      {:ok, response} -> manage_response(response, order)
      {:error, message} -> raise "ing payment request error: #{message}"
    end
  end

  def check_sig(body, signature) do
    :crypto.hash(:sha256, body <> @ing_service_key)
    |> Base.encode16(case: :lower)
    |> Kernel.==(signature)
  end

  def transfer_struct_to_twisto(nil), do: nil
  def transfer_struct_to_twisto(%{ "address" => %{ "shipping" => shipping }} = order) do
    customer = %{
      "email" => order["email"],
      "name" => shipping["name"]
    }

    delivery_address = %{
      "name" => shipping["name"] <> " " <> shipping["surname"],
      "street" =>  shipping["street"],
      "city" =>  shipping["city"],
      "zipcode" => shipping["post-code"] |> String.replace("-", ""),
      "phone_number" => shipping["phone-number"],
      "country" => shipping["country"]
    }

    shipping_method = %{
      "type" => 1,
      "name" => "shipment",
      "product_id" => order["shipping_code"],
      "quantity" => 1,
      "price_vat" => order["shipping_price"],
      "vat" => 23
    }
    
    items = 
      order["products"] 
      |> Enum.map(&(create_item(&1)))
      |> Kernel.++([shipping_method])

    twisto_order = %{
      "date_created" => order["created_at"],
      "billing_address" => delivery_address,
      "delivery_address" => delivery_address,
      "total_price_vat" => Float.round(order["order_total_price"], 2),
      "items" => items
    }

    data = %{
      "random_nonce" => Ecto.UUID.generate,
      "customer" => customer,
      "order" => twisto_order
    } |> Poison.encode!

    data_gzip = data |> gzip()
    data_size = data_gzip |> byte_size
    packed_data = <<data_size::unsigned-32>> <> data_gzip

    aes_key = generate_key(0..31)
    salt = generate_key(32..63)

    iv = :crypto.strong_rand_bytes(16)
    digest = :crypto.hmac(:sha256, salt, packed_data <> iv)
    encrypted = :crypto.aes_cbc_128_encrypt(aes_key, iv, pad(packed_data, 16))

    Base.encode64(iv <> digest <> encrypted)
  end

  defp generate_key(range) do
    @ing_twisto_secret_key 
    |> String.slice(8..-1)
    |> String.slice(range) 
    |> Base.decode16!(case: :mixed) 
  end

  defp payment_struct(order, nil) do
    %{
      "merchantId" => @ing_client_id,
      "serviceId" => @ing_service_id,
      "amount" => ing_price(order["order_total_price"]),
      "currency" => order["currency"],
      "orderId" => BSON.ObjectId.encode!(order["_id"]),
      "orderDescription" => "Zamówienie " <> BSON.ObjectId.encode!(order["_id"]) <> " - pl.manymornings.com",
      "customerFirstName" => order["address"]["shipping"]["name"],
      "customerLastName" => order["address"]["shipping"]["surname"],
      "customerEmail" => order["email"],
      "customerPhone" => order["address"]["shipping"]["phone-number"],
      "urlSuccess" => @ing_return_url,
      "urlFailure" => @ing_cancel_url,
      "urlReturn" => @ing_return_url,
    }
  end
  defp payment_struct(order, twisto) do
    payment_struct(order, nil) 
    |> Map.merge(%{ "twistoData" => twisto |> Poison.encode! })
  end

  defp gzip(data) do
    z = :zlib.open()
    :zlib.deflateInit(z, 9)
    data = :zlib.deflate(z, data, :finish)
    :zlib.deflateEnd(z)
    :zlib.close(z)
  
    data |> List.first
  end

  defp pad(data, block_size) do
    to_add = block_size - rem(byte_size(data), block_size)
    data <> to_string(:string.chars(to_add, to_add))
  end

  defp create_item(item) do
    %{
      "type" => item["type"] || 0,
      "name" =>  item["name"],
      "product_id" =>  item["variant_id"],
      "quantity" => item["count"] || 1,
      "price_vat" => item["total_price"],
      "vat" => 23
    }
  end

  defp manage_response(response, order) do
    redirect_url = case response do
      %HTTPoison.Response{body: _, headers: headers, status_code: 302 } -> headers |> Enum.into(%{}) |> Map.get("Location")
      response -> raise "ING order #{response} error"
    end

    case ORMongo.update_one("orders", %{"_id" => order["_id"]}, %{"redirect_url" => redirect_url}) do
      {:ok, _update_result} -> order |> Map.put_new("redirect_url", redirect_url)
      _ -> order
    end
  end

  defp post(url, params) do
    HTTPoison.post(@ing_api_url <> url, params, [{"Content-Type", "application/x-www-form-urlencoded"}], @ing_timeout)
  end

  defp create_signature(body) do
    :crypto.hash(:sha256, body <> @ing_service_key)
    |> Base.encode16(case: :lower)
    |> Kernel.<>(";sha256")
  end

  defp create_body_params(payment_info) do
    payment_info
    |> Enum.sort
    |> Enum.map(fn ({key, value})-> "#{key}=#{value}&" end) 
    |> Enum.join
  end

  defp ing_price(price) do
    price
    |> Kernel./(1) # be sure that price is INT
    |> Float.round(2)
    |> Kernel.*(100) # ING need price in 0,01
    |> round
  end
end