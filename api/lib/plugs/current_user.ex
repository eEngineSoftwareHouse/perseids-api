defmodule Perseids.Plugs.CurrentUser do
  import Plug.Conn
  alias Perseids.Session

  def init(options), do: options

  @doc """
    Retrieves user magento authorization token from session_id (passed as Bearer),
    and adds it into the conn for further usage
  """
  def call(conn, _) do
    try do
      session_id = get_req_header(conn, "authorization")
      |> List.first

      session = Session.find_one(session_id)
      case session["magento_token"] do
       nil -> conn
       _ ->
         conn
         |> assign(:session_id, session_id)
         |> assign(:magento_token, session["magento_token"])
         |> assign(:group_id, session["group_id"] |> Integer.to_string)
         |> assign(:customer_id, session["customer_id"])
         |> assign(:tax_rate, session["tax_rate"])
         |> assign(:wholesale, session["wholesale"])
         |> assign(:admin, session["admin"])
      end
    rescue
        _ -> conn
    end
  end
end
