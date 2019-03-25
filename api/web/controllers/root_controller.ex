defmodule Perseids.RootController do
  use Perseids.Web, :controller

  def divider(conn, _params) do
    conn
    |> put_status(204)
    |> json("ok")
  end
end