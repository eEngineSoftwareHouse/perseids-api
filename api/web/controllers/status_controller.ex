defmodule Perseids.StatusController do
  use Perseids.Web, :controller

  def magento(conn, _params) do
    magento = %{
      online: conn.assigns[:store_view] |> Magento.online?
    }
    render conn, "magento.json", magento: magento
  end

  def robots(conn, _params) do
    text conn, "User-agent: *\nAllow: /"
  end

end
