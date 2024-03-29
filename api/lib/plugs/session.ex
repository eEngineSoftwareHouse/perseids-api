defmodule Perseids.Plugs.Session do
  import Plug.Conn
  alias Perseids.Session
  import Perseids.Gettext
  
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
       nil -> conn |> unauthorized
       _ ->
         conn
         |> assign(:session_id, session_id)
         |> assign(:magento_token, session["magento_token"])
         |> assign(:customer_id, session["customer_id"])
         |> assign(:group_id, session["group_id"] |> Integer.to_string)
         |> assign(:wholesale, session["wholesale"])
         |> assign(:admin, session["admin"])
         |> assign(:tax_rate, session["tax_rate"])
      end
    rescue
        _ -> conn |> unauthorized
    end
  end

  def unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Poison.encode!(%{errors: [gettext "You do not have sufficient permissions."]}))
    |> halt()
  end
end
