defmodule FreshMail do
  import Perseids.Gettext
  
  @fresh_mail_host Application.get_env(:perseids, :fresh_mail)[:api_url]
  @fresh_mail_key  Application.get_env(:perseids, :fresh_mail)[:api_key]
  @fresh_mail_secret Application.get_env(:perseids, :fresh_mail)[:api_secret]
  @default_headers [{ "Content-Type", "application/json" }, { "X-Rest-ApiKey", @fresh_mail_key }]

  def save_email(%{"email" => _email, "list" => _list} = params) do
    encoded_params = params |> Poison.encode!
    sha1 = 
      @fresh_mail_key  <> "/rest/subscriber/add" <> encoded_params <> @fresh_mail_secret
      |> encode_to_sha1 

    headers = [{ "X-Rest-ApiSign", sha1 }]

    case post("subscriber/add", encoded_params, headers) do
      { :ok, response } -> response(response)
      { :error, reason } -> { 500, reason }
    end
  end

  def save_email(_params) do
    { 400, Gettext.gettext(Perseids.Gettext,"Email was not passed") }
  end

  defp response(response) do
    case response.status_code do
      200 -> { 200, "ok" }
      _ -> 
        { response.status_code, 
          [
            response.body 
            |> Poison.decode! 
            |> Map.get("errors") 
            |> Enum.map(&(Map.fetch!(&1, "message"))) 
            |> translated_message 
          ] 
        }
    end
  end

  defp post(url, params, headers), do: HTTPoison.post(@fresh_mail_host <> url, params, @default_headers ++ headers)

  defp encode_to_sha1(fresh_mail_request), do: :crypto.hash(:sha, fresh_mail_request) |> Base.encode16 |> String.downcase

  defp translated_message(messages), do: messages |> Enum.map(&(Gettext.gettext(Perseids.Gettext, &1)))

end
