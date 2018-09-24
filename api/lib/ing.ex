defmodule ING do
  @ing_api_url Application.get_env(:perseids, :ing)[:api_url]
  @ing_client_id Application.get_env(:perseids, :ing)[:client_id]
  @ing_service_id Application.get_env(:perseids, :ing)[:service_id]
  @ing_service_key Application.get_env(:perseids, :ing)[:service_key]
  @ing_return_url Application.get_env(:perseids, :ing)[:return_url]
  @ing_cancel_url Application.get_env(:perseids, :ing)[:cancel_url]
  @ing_timeout [connect_timeout: 30000, recv_timeout: 30000, timeout: 30000]

  def create_payment(%{"currency" => currency, "order_total_price" => order_total_price} = order) do
    # %{ "twisto_transaction_id" => twisto_transaction_id, "twisto_status" => twisto_status } =
    #   twisto_payment
    #   |> transfer_struct_to_twisto(order)

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

  def twisto_payment do
    signature =
      :crypto.hash(:sha256, @ing_service_key)
      |> Base.encode16(case: :lower)
    case get("check/methods", [{"Content-Type", "application/x-www-form-urlencoded"}, {"X-Imoje-Signature", "merchantid=#{@ing_client_id};serviceid=#{@ing_service_id};signature=#{signature};alg=sha256"}]) do
      {:ok, %HTTPoison.Response{body: body}} -> body |> Poison.decode!
      {:error, message} -> raise "ing twisto request error: #{message}"
    end 
  end

  def transfer_struct_to_twisto(%{ "data" => %{ "twisto" => %{ "enable" => true, "pk" => twisto_pk, "sk" => twisto_sk}}}, %{ "address" => %{ "shipping" => shipping }} = order) do
    customer = %{
      "email" => order["email"],
      "name" => shipping["name"]
    }
    delivery_address = %{
      "name" => shipping["name"],
      "street" =>  shipping["street"],
      "city" =>  shipping["city"],
      "zipcode" => shipping["post-code"],
      "phone_number" => shipping["phone-number"],
      "country" => shipping["country"]
    }
    billing_address = %{
      "name" => "Adrian Morawiak, Maciej Butkowski",
      "street" =>  "ul. Kalinowa 2",
      "city" =>  "Aleksandrów Łódzki",
      "zipcode" => "95-070",
      "phone_number" => "+48 570 003 961",
      "country" => "PL"
    }

    shipping_method = %{
      "type" => 1,
      "name" => "shipment",
      "product_id" => order["shipping_code"],
      "quantity" => 1,
      "price_vat" => order["shipping_price"],
      "vat" => 23
    }


    items = order["products"] |> Enum.map(&(create_item(&1)))
    twisto_order = %{
      "date_created" => order["created_at"],
      "billing_address" => billing_address,
      "devlivery_address" => delivery_address,
      "total_price_vat" => order["order_total_price"],
      "items" => items
    }

    data = %{
      "random_nonce" => Ecto.UUID.generate,
      "customer" => customer,
      "order" => twisto_order
    } |> Poison.encode!
      data_gzip = data |> :zlib.gzip
      data_size = data_gzip |> byte_size
      vvv = <<data_size::32>> <> data_gzip

    secret_key = twisto_sk |> String.slice(8..-1)
    bin_key = secret_key |> Base.decode16!(case: :mixed) 
    # bin_key = for <<x::binary-2 <- secret_key>>, do: x
    # bbb = bin_key |> Enum.map(&(Base.decode16!(&1, case: :mixed)))
    # aes_key = bbb |> Enum.take(16)
    aes_key = bin_key |> String.slice(0..13)
    # salt = bbb |> Enum.reverse |> Enum.take(16) |> Enum.reverse
    salt = bin_key |> String.slice(14..29)

    # iv = :crypto.strong_rand_bytes(16)
    iv = "EEH\rS2\xE7\xB6\xF2\xC4\xB7\xEF\xE5\xF6^k"
    encrypted = :crypto.aes_cbc_128_encrypt(aes_key, iv, pad(vvv,16))
    digest = :crypto.hmac(:sha256, salt, data <> iv)

    result = Base.encode64(iv <> digest <> encrypted)

    HTTPoison.post("http://api.twisto.pl/v2/", result)
  end

  def pad(data, block_size) do
    to_add = block_size - rem(byte_size(data), block_size)
    data <> to_string(:string.chars(to_add, to_add))
  end

  def create_item(item) do
    %{
      "type" => item["type"] || 0,
      "name" =>  item["name"],
      "product_id" =>  item["id"],
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

  defp get(url, headers) do
    HTTPoison.get(@ing_api_url <> url, headers, @ing_timeout)
  end

  defp post(url, params) do
    HTTPoison.post(@ing_api_url <> url, params, [{"Content-Type", "application/x-www-form-urlencoded"}], @ing_timeout)
  end

  # defp post(url, params, headers) do
  #   HTTPoison.post(@ing_api_url <> url, params, headers, @ing_timeout)
  # end

  defp create_signature(body) do
    :crypto.hash(:sha256, body <> @ing_service_key)
    |> Base.encode16(case: :lower)
    |> Kernel.<> ";sha256"
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