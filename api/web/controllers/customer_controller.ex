defmodule Perseids.CustomerController do
  use Perseids.Web, :controller

  def info(conn, _params) do
    case Magento.customer_info(conn.assigns[:magento_token]) do
        {:ok, response} -> 
          response = Perseids.CustomerHelper.default_lang(response)
          json(conn, response)
        {:error, message} -> json(conn, %{ errors: [message] })
    end
  end

  def address(conn, %{"address_type" => address}) do
    case Magento.address_info(conn.assigns[:magento_token], address) do
        {:ok, response} -> json(conn, response)
        {:error, message} -> json(conn, %{ errors: [message] })
    end
  end

  def create(conn, params) do
    case Magento.create_account(params) do
        {:ok, response} -> 
          response = Perseids.CustomerHelper.default_lang(response)
          json(conn, response)
        {:error, message} -> json(conn, %{ errors: [message] })
    end
  end

  def update(conn, params) do
    case filtered_params(params) |> Magento.update_account(customer_id: conn.assigns[:customer_id], customer_token: conn.assigns[:magento_token]) do
        {:ok, response} -> 
          response = Perseids.CustomerHelper.default_lang(response)
          json(conn, Map.put_new(response, :session_id, conn.assigns[:session_id]))
        {:error, message} -> json(conn, %{ errors: [message] })
    end
  end

  def password_reset(conn, %{"email" => _email, "website_id" => _website_id} = params), do: reset_password(true, params, conn)
  def password_reset(conn, %{"password" => password, "password_confirmation" => password_confirmation, "token" => _token, "email" => _email} = params), do: reset_password(password_confirmation == password, params, conn)


  defp reset_password(false, _params, conn), do: json(conn, %{errors: ["Passwords are not the same"]})
  defp reset_password(true, params, conn) do
    case Magento.reset_password(params) do
        {:ok, response} -> json(conn, response)
        {:error, message} -> json(conn, %{ errors: [message] })
    end
  end

  defp filtered_params(params) do
    whitelisted_params = ~w(website_id lastname firstname addresses)
    %{ "customer" => Enum.reduce(params["customer"], %{}, &(maybe_put_key(&1, &2, whitelisted_params))) }
  end

  defp maybe_put_key({ key, value }, params, whitelisted_params) do
    Enum.member?(whitelisted_params, key)
    |> maybe_put_key(params, key, value)
  end
  
  defp maybe_put_key(true, params, key, value), do: Map.put(params, key, value)
  defp maybe_put_key(false, params, _key, _value), do: params

end
