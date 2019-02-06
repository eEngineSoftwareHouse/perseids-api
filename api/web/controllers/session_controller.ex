defmodule Perseids.SessionController do
  use Perseids.Web, :controller

  alias Perseids.Session

  def create(conn, %{"email" => email, "password" => password} = _params) do
    case conn.assigns[:store_view] |> Magento.customer_token(%{username: email, password: password}) do
      {:ok, magento_token} ->
        {:ok, customer_info} = conn.assigns[:store_view] |> Magento.customer_info(magento_token)

        session_data = %{
          magento_token: magento_token, 
          customer_id: customer_info["id"], 
          group_id: customer_info["group_id"], 
          wholesale: customer_info["is_wholesaler"],
          admin: customer_info["admin"],
          tax_rate: customer_info["tax_rate"] || 23
        }

        changeset = Session.changeset(%Perseids.Session{}, session_data)

        session_id = Session.create(changeset.changes)["_id"]
        |> BSON.ObjectId.encode!
      

        response = 
          customer_info
          |> Perseids.CustomerHelper.default_lang
          |> Perseids.CustomerHelper.wholesale_debt_limit
          |> Map.put_new(:session_id, session_id)
        
        json(conn, response)

      {:error, message} ->
        conn
        |> put_status(422)
        |> render("error.json", message: message)

      _ -> 
        conn
        |> put_status(422)
        |> render("error.json", message: gettext "Unknown error occured")
    end
  end

  def destroy(conn, _params) do
    try do
      get_req_header(conn, "authorization")
      |> List.first
      |> Session.destroy
      json(conn, true)
    rescue
      _ -> conn |> put_status(422) |> json(%{errors: gettext "Logout failed"})
    end
  end
end
