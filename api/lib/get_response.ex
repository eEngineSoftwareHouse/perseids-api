defmodule GetResponse do
  @gr_host Application.get_env(:perseids, :get_response)[:api_url]
  @gr_token "api-key " <> Application.get_env(:perseids, :get_response)[:api_key]
  @gr_campaign Application.get_env(:perseids, :get_response)[:api_campaign_token]
  # @gr_host "https://api.getresponse.com/v3/"
  # @gr_token "api-key 7ccbc6e77e02eddf9608741c01fc9113"
  # @gr_campaign "4pQR6"
  @default_headers [{"Content-Type", "application/json"}, {"X-Auth-Token", @gr_token}]

  def save_email(%{"email" => email} = params) do
    body = params
    |> Map.put_new(:campaign, %{campaignId: @gr_campaign})

    case post("contacts", body) do
      { :ok, response } -> response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def save_email(_params) do
    %{error: "Nie podano adresu email"}
  end

  defp response(response) do
    case response.status_code do
      # GetResponse return 202 on success, because email will be visible about 1 minute later
      202 -> Poison.decode!(response.body)
      _ -> %{ errors: [response.body |> Poison.decode! |> Map.get("codeDescription")] }
    end
  end

  defp get(url, headers \\ []) do
    HTTPoison.get(@gr_host <> url, @default_headers ++ headers)
  end

  defp post(url, params \\ %{}, headers \\ []) do
    HTTPoison.post(@gr_host <> url, Poison.encode!(params), @default_headers ++ headers)
  end

  defp put(url, params \\ %{}, headers \\ []) do
    HTTPoison.put(@gr_host <> url, Poison.encode!(params), @default_headers ++ headers)
  end

end
