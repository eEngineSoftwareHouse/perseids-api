defmodule Magento do
  @magento_host Application.get_env(:perseids, :magento)[:magento_api_endpoint]
  @magento_timeout [connect_timeout: 60000, recv_timeout: 60000, timeout: 60000]
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

  def address_info(token, address_type) do
    case get("customers/me/#{address_type}Address", [{"Authorization", "Bearer #{token}"}]) do
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

  def update_account(params, customer_id: customer_id, customer_token: customer_token) do
    {:ok, token} = admin_token()
    params = %{ "customer" => set_customer_email(customer_token, params) }
    case put("customers/#{customer_id}", Poison.encode!(params), [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  defp set_customer_email(token, params) do
    case customer_info(token) do
      {:ok, customer} -> params["customer"] |> Map.put("email", customer["email"])
      {:error, reason} -> params
    end
  end

  def reset_password(%{"email" => _email, "website_id" => _website_id} = params) do
    {:ok, token} = admin_token()
    case put("customers/password", Poison.encode!(params |> Map.put_new("template", "email_reset")), [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def reset_password(%{"password" => password, "password_confirmation" => _password_confirmation, "token" => token, "email" => email}) do
    case put("base/password", Poison.encode!(%{"newPassword" => password, "resetToken" => token, "email" => email})) do
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
      _ -> { :error, response.body |> Poison.decode! |> maybe_parametrized_message }
    end
  end

  defp maybe_parametrized_message(%{"message" => message, "parameters" => parameters} = _body) do
    parameters 
    |> Enum.with_index(1) # changes ["string1", "string2"] into [{"string1", 1}, {"string2", 2}]
    |> Enum.reduce(message, &(substitute_magento_vars(&1, &2)))
  end

  defp maybe_parametrized_message(%{"message" => message} = _body), do: message

  defp substitute_magento_vars(var, str) do
    {word, index} = var
    String.replace(str, "%#{index}", word)
  end

  defp get(url, headers) do
    HTTPoison.get(@magento_host <> url, [{"Content-Type", "application/json"} | headers], @magento_timeout)
  end

  defp post(url, params \\ Poison.encode!(%{}), headers \\ []) do
    HTTPoison.post(@magento_host <> url, params, [{"Content-Type", "application/json"} | headers], @magento_timeout)
  end

  defp put(url, params, headers \\ []) do
    HTTPoison.put(@magento_host <> url, params, [{"Content-Type", "application/json"} | headers], @magento_timeout)
  end

end
