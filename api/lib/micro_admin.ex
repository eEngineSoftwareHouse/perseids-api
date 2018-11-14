defmodule MicroAdmin do
  @micro_admin_host Application.get_env(:perseids, :micro_admin)[:base_url]
  @micro_admin_timeout [connect_timeout: 60000, recv_timeout: 60000, timeout: 60000]
  @micro_admin_credentials %{
    username: Application.get_env(:perseids, :micro_admin)[:jwt_auth_user],
    password: Application.get_env(:perseids, :micro_admin)[:jwt_auth_pass]
  }

  def admin_token do
    case post("identity/tokens", Poison.encode!(@micro_admin_credentials)) do
      { :ok, response } -> micro_admin_response(response, 201)
      { :error, reason } -> raise reason
    end
  end

  def wholesaler_limit(email, func) do
    case admin_token do
      { :ok, %{ "jwt" => token } } -> wholesaler_limit(email, token)
      { :error, reason } -> "error"
    end
  end 

  def wholesaler_limit(email, token) do
    case get("order/customers/#{email}", [{"Authorization", "Bearer #{token}"}]) do
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

  defp micro_admin_response(response, status_code \\ 200) do
    case response.status_code do
      status_code -> { :ok, response.body |> Poison.decode! }
      _ -> { :error, response.body |> Poison.decode! }
    end
  end

end