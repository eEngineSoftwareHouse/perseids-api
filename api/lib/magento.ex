defmodule Magento do
  @magento_host Application.get_env(:perseids, :magento)[:magento_api_endpoint]
  @magento_admin_credentials %{
    username: Application.get_env(:perseids, :magento)[:admin_username],
    password: Application.get_env(:perseids, :magento)[:admin_password]
  }

  def online? do
    case post("integration/customer/token") do
      { :ok, _response } -> true
      { :error, _reason } -> false
    end
  end

  def store_configs do
    case admin_token() do
      { :ok, token } ->
        case get("store/storeConfigs", [{"Authorization", "Bearer #{token}"}]) do
          { :ok, response } -> response.body
          { :error, reason } -> reason
        end
      { :error, message } -> message
    end
    |> Poison.decode!

  end

  def admin_token do
    case post("integration/admin/token", Poison.encode!(@magento_admin_credentials)) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def customer_token(credentials) do
    case post("integration/customer/token", Poison.encode!(credentials)) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end


  def customer_info(token) do
    case get("customers/me", [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def create_account(params) do
    {:ok, token} = admin_token()
    case post("customers", Poison.encode!(params), [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def update_account(params, customer_id: customer_id) do
    {:ok, token} = admin_token()
    case put("customers/#{customer_id}", Poison.encode!(params), [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def product_stock(sku) do
    {:ok, token} = admin_token()
    case get("stockItems/#{sku}", [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> %{errors: [reason]}
    end
  end

  # magento nie pozwala zapytać o stock wielu produktów jednocześnie, więc dla każdego idzie request,
  # do zmiany po rozbudowie API magento naszą wtyczką
  def stock_items(sku_list) do
    {:ok, token} = admin_token()
    products_qty(sku_list, %{}, token)
  end

  defp products_qty([head | tail], accumulator, token) do
    accumulator = case get("stockItems/#{head}", [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } ->
        case magento_response(response) do
          { :ok, stock } -> Map.put_new(accumulator, "#{head}", stock["qty"])
          _ -> accumulator
        end
      _ -> accumulator
    end
    products_qty(tail, accumulator, token)
  end

  defp products_qty([], accumulator, _token) do
    accumulator
  end

  defp magento_response(response) do
    case response.status_code do
      200 -> { :ok, Poison.decode!(response.body) }
      _ -> { :error, response.body |> Poison.decode! |> Map.get("message") }
    end
  end

  defp get(url, headers) do
    HTTPoison.get(@magento_host <> url, [{"Content-Type", "application/json"} | headers])
  end

  defp post(url, params \\ Poison.encode!(%{}), headers \\ []) do
    HTTPoison.post(@magento_host <> url, params, [{"Content-Type", "application/json"} | headers])
  end

  defp put(url, params, headers) do
    HTTPoison.put(@magento_host <> url, params, [{"Content-Type", "application/json"} | headers])
  end

end
