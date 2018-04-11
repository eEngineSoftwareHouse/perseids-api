defmodule Perseids.Plugs.Language do
  import Plug.Conn

  def init(options), do: options

  @doc """
  Retrieves user language from Client-Language header,
  and adds it into the conn for further usage
  """
  def call(conn, _) do
    get_req_header(conn, "client-language")
    |> List.first
    |> extract_currency_code(conn)
  end

  defp extract_currency_code(nil, conn), do: conn |> assign(:lang, "pl_pln")

  defp extract_currency_code(prefix, conn) do
    [locale, currency] = prefix |> String.split("_")
    
    Gettext.put_locale(Perseids.Gettext, locale)

    conn
    |> assign(:lang, prefix)
    |> assign(:locale, locale)
    |> assign(:store_view, get_corresponding_store_view(prefix))
    |> assign(:currency, currency |> String.upcase)
    |> assign(:fresh_mail_list_id, fresh_mail_list_id(locale))
  end

  defp get_corresponding_store_view(lang) do
    store_views = %{
      "pl_pln" => "plpl",
      "en_eur" => "eneu",
      "en_gbp" => "engbp",
      "en_usd" => "enus"
    }
    store_views[lang]
  end

  defp fresh_mail_list_id("pl"), do: Application.get_env(:perseids, :fresh_mail)[:api_list_token_pl]
  defp fresh_mail_list_id(_locale), do: Application.get_env(:perseids, :fresh_mail)[:api_list_token_en]
end
