defmodule GetResponse do
  import Perseids.Gettext
  
  @gr_host Application.get_env(:perseids, :get_response)[:api_url]
  @gr_token "api-key " <> Application.get_env(:perseids, :get_response)[:api_key]
  # @gr_campaign Application.get_env(:perseids, :get_response)[:api_campaign_token]
  @default_headers [{"Content-Type", "application/json"}, {"X-Auth-Token", @gr_token}]

  def save_email(%{"email" => _email, "campaign" => %{"campaignId" => _campaign_id}} = params) do
    case post("contacts", params) do
      { :ok, response } -> response(response)
      { :error, reason } -> {:error, reason}
    end
  end

  def save_email(_params) do
    %{error: gettext "Email was not passed"}
  end

  defp response(response) do
    case response.status_code do
      # GetResponse return 202 on success, because email will be visible about 1 minute later
      202 -> Poison.decode!(response.body)
      _ -> %{ errors: [response.body |> Poison.decode! |> Map.get("codeDescription") |> translated_message] }
    end
  end

  defp post(url, params, headers \\ []) do
    HTTPoison.post(@gr_host <> url, Poison.encode!(params), @default_headers ++ headers)
  end

  defp translated_message(message), do: Gettext.gettext(Perseids.Gettext, message)
end
