defmodule Perseids.StatusController do
  use Perseids.Web, :controller

  def magento(conn, _params) do
    magento = %{
      online: conn.assigns[:store_view] |> Magento.online?
    }
    render conn, "magento.json", magento: magento
  end
end
