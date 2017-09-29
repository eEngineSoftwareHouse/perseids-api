defmodule Perseids.SessionController do
  use Perseids.Web, :controller

  alias Perseids.Session

  def create(conn, %{"email" => email, "password" => password} = _params) do
    case Magento.customer_token(%{username: email, password: password}) do
      {:ok, magento_token} ->
        {:ok, customer_info} = Magento.customer_info(magento_token)
        changeset = Session.changeset(%Perseids.Session{}, %{magento_token: magento_token, customer_id: customer_info["id"]})

        session_id = Session.create(changeset.changes)["_id"]
        |> BSON.ObjectId.encode!

        json(conn, Map.put_new(customer_info, :session_id, session_id))

      {:error, message} -> render conn, "error.json", message: message
      _ -> render conn, "error.json", message: "Unknown error occured"
    end
  end

  def destroy(conn, _params) do
    try do
      get_req_header(conn, "authorization")
      |> List.first
      |> Session.destroy
      json(conn, true)
    rescue
      _ -> json(conn, %{errors: "Wylogowanie nie powiodło się"})
    end
  end

  def options(_conn) do
  end
end
