defmodule Perseids.NavbarController do
  use Perseids.Web, :controller
  alias Perseids.Navbar

  def index(conn, params) do
    navbars = Helpers.to_keyword_list(params)
    |> ORMongo.set_language(conn)
    |> Navbar.find

    render conn, "index.json", navbars: navbars
  end

  def update(conn, params) do
    Navbar.changeset(%Perseids.Navbar{}, prepare_params(conn, params))
    |> valid_changeset?
    |> do_action(conn)
    |> response_with(conn)
  end

  defp valid_changeset?(changeset) do
    {changeset.valid?, changeset}
  end

  defp do_action({true, changeset}, _conn), do: Navbar.update(changeset.changes) 
  defp do_action({false, changeset}, conn), do: render conn |> put_status(422), "errors.json", changeset: changeset

  defp response_with(navbars, conn), do: render conn, "index.json", navbars: navbars

  defp prepare_params(conn, params) do
    params
    |> Map.put_new("lang", conn.assigns.lang)
  end
end
