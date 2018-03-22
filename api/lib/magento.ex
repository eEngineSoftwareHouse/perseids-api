defmodule Magento do
  import Perseids.Gettext

  @magento_host Application.get_env(:perseids, :magento)[:magento_api_endpoint]
  @magento_timeout [connect_timeout: 60000, recv_timeout: 60000, timeout: 60000]
  @magento_admin_credentials %{
    username: Application.get_env(:perseids, :magento)[:admin_username],
    password: Application.get_env(:perseids, :magento)[:admin_password]
  }

  def online?(store_view) do
    case store_view |> post("integration/customer/token") do
      { :ok, _response } -> true
      { :error, _reason } -> false
    end
  end

  def store_configs(store_view) do
    case admin_token(store_view) do
      { :ok, token } ->
        case store_view |> get("store/storeConfigs", [{"Authorization", "Bearer #{token}"}]) do
          { :ok, response } -> response.body
          { :error, reason } -> reason
        end
      { :error, message } -> message
    end
    |> Poison.decode!

  end

  def admin_token(store_view) do
    case store_view |> post("integration/admin/token", Poison.encode!(@magento_admin_credentials)) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def customer_token(store_view, credentials) do
    case store_view |> post("integration/customer/token", Poison.encode!(credentials)) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end


  def customer_info(store_view, token) do
    case store_view |> get("customers/me", [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def address_info(store_view, token, address_type) do
    case store_view |> get("customers/me/#{address_type}Address", [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def create_account(store_view, params) do
    {:ok, token} = admin_token(store_view)
    case store_view |> post("customers", Poison.encode!(params), [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def update_account(store_view, params, customer_id: customer_id, customer_token: customer_token, group_id: group_id) do
    {:ok, token} = admin_token(store_view)
    params = %{ "customer" => set_customer_email(store_view, customer_token, params) |> Map.put("group_id", group_id) }
    case store_view |> put("customers/#{customer_id}", Poison.encode!(params), [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  defp set_customer_email(store_view, token, params) do
    case customer_info(store_view, token) do
      {:ok, customer} -> params["customer"] |> Map.put("email", customer["email"])
      {:error, _reason} -> params
    end
  end

  def reset_password(store_view, %{"email" => _email, "website_id" => _website_id} = params) do
    {:ok, token} = admin_token(store_view)
    case store_view |> put("customers/password", Poison.encode!(params |> Map.put_new("template", "email_reset")), [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def reset_password(store_view, %{"password" => password, "password_confirmation" => _password_confirmation, "token" => token, "email" => email}) do
    case store_view |> put("base/password", Poison.encode!(%{"newPassword" => password, "resetToken" => token, "email" => email})) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def product_stock(store_view, sku) do
    {:ok, token} = admin_token(store_view)
    case store_view |> get("stockItems/#{sku}", [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } -> magento_response(response)
      { :error, reason } -> %{errors: [reason]}
    end
  end

  # magento nie pozwala zapytać o stock wielu produktów jednocześnie, więc dla każdego idzie request,
  # do zmiany po rozbudowie API magento naszą wtyczką
  def stock_items(store_view, sku_list) do
    {:ok, token} = admin_token(store_view)
    products_qty(store_view, sku_list, %{}, token)
  end

  defp products_qty(store_view, [head | tail], accumulator, token) do
    accumulator = case store_view |> get("stockItems/#{head}", [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } ->
        case magento_response(response) do
          { :ok, stock } -> Map.put_new(accumulator, "#{head}", stock["qty"])
          _ -> accumulator
        end
      _ -> accumulator
    end
    products_qty(store_view, tail, accumulator, token)
  end

  defp products_qty(_store_view, [], accumulator, _token) do
    accumulator
  end

  defp magento_response(response) do
    case response.status_code do
      200 -> { :ok, Poison.decode!(response.body) }
      _ -> { :error, response.body |> Poison.decode! |> maybe_parametrized_message }
    end
  end

  defp maybe_parametrized_message(%{"message" => message, "parameters" => [_]} = body) do
    body["parameters"]
    |> Enum.with_index(1) # changes ["string1", "string2"] into [{"string1", 1}, {"string2", 2}]
    |> Enum.map(fn(elem) -> {word, index} = elem; {"#{index}", word} end)
    |> Enum.reduce(translated_message(message), &(substitute_magento_vars(&1, &2)))
  end

  defp maybe_parametrized_message(%{"message" => message, "parameters" => %{}} = body) do
    body["parameters"]
    |> Enum.reduce(translated_message(message), &(substitute_magento_vars(&1, &2)))
  end

  defp maybe_parametrized_message(%{"message" => message} = _body), do: translated_message(message)

  defp substitute_magento_vars(var, str) do
    {index, word} = var
    String.replace(str, "%#{index}", "#{word}")
  end

  defp get(store_view, url, headers) do
    HTTPoison.get(magento_api_url(url, store_view), [{"Content-Type", "application/json"} | headers], @magento_timeout)
  end

  defp post(store_view, url, params \\ Poison.encode!(%{}), headers \\ []) do
    HTTPoison.post(magento_api_url(url, store_view), params, [{"Content-Type", "application/json"} | headers], @magento_timeout)
  end

  defp put(store_view, url, params, headers \\ []) do
    HTTPoison.put(magento_api_url(url, store_view), params, [{"Content-Type", "application/json"} | headers], @magento_timeout)
  end
  
  defp magento_api_url(url, store_view), do: @magento_host <> "rest/" <> store_view <> "/V1/" <> url

  defp translated_message(message), do: Gettext.gettext(Perseids.Gettext, message)
end
