defmodule Perseids.Plugs.Language do
  import Plug.Conn

  def init(options), do: options

  @doc """
  Retrieves user language from Client-Language header,
  and adds it into the conn for further usage
  """
  def call(conn, _) do
    case get_req_header(conn, "client-language") |> List.first do
      nil -> conn |> assign(:lang, "pl_pln")
      lang ->  conn |> assign(:lang, lang)
    end
  end
end
