defmodule Perseids.Plugs.Wholesale do
  import Plug.Conn
  alias Perseids.Session
  import Perseids.Gettext

  def init(options), do: options

  @doc """
    Checks if logged user is a wholesaler and adds proper info to conn
  """
  def call(conn, _) do
    case conn.assigns.wholesale do
      true -> conn
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
