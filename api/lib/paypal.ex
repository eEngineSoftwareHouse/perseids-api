defmodule PayPal do
  @paypal_api_url Application.get_env(:perseids, :paypal)[:api_url]
  @paypal_client_id Application.get_env(:perseids, :paypal)[:client_id]
  @paypal_client_secret Application.get_env(:perseids, :paypal)[:client_secret]

  def oauth_token() do
    auth = [basic_auth: {@paypal_client_id, @paypal_client_secret}]
    body = "grant_type=client_credentials"
    case HTTPoison.post(@paypal_api_url <> "oauth2/token", body, [{"Content-Type", "application/x-www-form-urlencoded"}], hackney: auth) do
      { :ok, response } -> paypal_response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  defp paypal_response(response) do
    case response.status_code do
      200 -> { :ok, Poison.decode!(response.body) }
      _ -> { :error, response.body |> Poison.decode! |> Map.get("error_description") }
    end
  end

  defp post(url, params, headers, options) do
    HTTPoison.post(@paypal_api_url <> url, params, [{"Content-Type", "application/json"}, {"Authorization", "Bearer #{token()}"} | headers], options)
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
