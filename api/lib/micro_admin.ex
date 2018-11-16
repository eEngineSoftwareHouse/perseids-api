defmodule MicroAdmin do
  @micro_admin_host Application.get_env(:perseids, :micro_admin)[:base_url]
  @micro_admin_timeout [connect_timeout: 60000, recv_timeout: 60000, timeout: 60000]
  @micro_admin_credentials %{
    username: Application.get_env(:perseids, :micro_admin)[:jwt_auth_user],
    password: Application.get_env(:perseids, :micro_admin)[:jwt_auth_pass]
  }

  def admin_token do
    case post("micro/admin/identity/tokens", Poison.encode!(@micro_admin_credentials)) do
      { :ok, response } -> micro_admin_response(response)
      { :error, reason } -> micro_admin_response(reason)
    end
  end

  def wholesaler_limit(email) do
    case admin_token do
      { :ok, %{ "jwt" => token } } -> wholesaler_limit(email, token)
      { :error, reason } -> { :error, reason }
    end
  end 

  def wholesaler_limit(email, token) do
    case get("micro/order/order/customers/#{email}", [{"Authorization", "Bearer #{token}"}]) do
      { :ok, response } -> micro_admin_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  defp get(url, headers) do
    HTTPoison.get(@micro_admin_host <> url, [{"Content-Type", "application/json"} | headers], @micro_admin_timeout)
  end

  defp post(url, params \\ Poison.encode!(%{}), headers \\ []) do
    HTTPoison.post(@micro_admin_host <> url, params, [{"Content-Type", "application/json"} | headers], @micro_admin_timeout)
  end

  defp put(url, params, headers \\ []) do
    HTTPoison.put(@micro_admin_host <> url, params, [{"Content-Type", "application/json"} | headers], @micro_admin_timeout)
  end

  defp micro_admin_response(response) do
    case response.status_code do
      200 -> { :ok, response.body |> Poison.decode! }
      201 -> { :ok, response.body |> Poison.decode! }
      400 -> { :error, %{ "Bad request" => 400 } }
      404 -> { :error, %{ "Not Found" => 404 } }
      422 -> { :error, %{ "Unprocessable Entity" => 422 } }
      500 -> { :error, %{ "Internal Server Error" => 500 } }
      _   -> { :error, %{ "Error with status code" => response.status_code } }
    end
  end

end