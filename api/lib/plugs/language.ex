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
    currency = prefix
    |> String.split("_")
    |> List.last
    |> String.upcase

    conn
    |> assign(:lang, prefix)
    |> assign(:currency, currency)
  end
end
