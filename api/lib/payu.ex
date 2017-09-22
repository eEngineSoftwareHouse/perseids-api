defmodule PayU do
  @payu_api_url Application.get_env(:perseids, :payu)[:api_url]
  @payu_pos_id Application.get_env(:perseids, :payu)[:pos_id]
  @payu_credentials %{
    grant_type: "client_credentials",
    client_id: Application.get_env(:perseids, :payu)[:client_id],
    client_secret: Application.get_env(:perseids, :payu)[:client_secret]
  }

  def oauth_token do
    body = "grant_type=#{@payu_credentials.grant_type}&client_id=#{@payu_credentials.client_id}&client_secret=#{@payu_credentials.client_secret}"
    case HTTPoison.post(@payu_api_url <> "pl/standard/user/oauth/authorize", body, [{"Content-Type", "application/x-www-form-urlencoded"}]) do
      { :ok, response } -> payu_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  defp payu_response(response) do
    case response.status_code do
      200 -> { :ok, Poison.decode!(response.body) }
      _ -> { :error, response.body |> Poison.decode! |> Map.get("error_description") }
    end
  end

  defp get(url, headers \\ []) do
    HTTPoison.get(@payu_api_url <> url, [{"Content-Type", "application/json"} | headers])
  end

  defp post(url, params \\ Poison.encode!(%{}), headers \\ []) do
    HTTPoison.post(@payu_api_url <> url, params, [{"Content-Type", "application/json"} | headers])
  end

  defp put(url, params \\ Poison.encode!(%{}), headers \\ []) do
    HTTPoison.put(@payu_api_url <> url, params, [{"Content-Type", "application/json"} | headers])
  end

end
