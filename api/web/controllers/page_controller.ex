defmodule Perseids.PageController do
  use Perseids.Web, :controller
  alias Perseids.Page

  def index(conn, params) do
    pages = Helpers.to_keyword_list(params)
    |> ORMongo.set_language(conn)
    |> Page.find

    render conn, "index.json", pages: pages
  end

  def show(%{assigns: %{lang: lang}} = conn, %{"slug" => slug}) do
    with page <- Page.find_one(slug: slug, lang: lang),
      true <- page["active"] 
    do
      render conn, "page.json", page: page
    else 
      _ -> conn |> put_status(404) |> json(:not_found)
    end
  end

  def create(conn, params) do
    Page.changeset(%Perseids.Page{}, prepare_params(conn, params))
    |> valid_changeset?
    |> do_action(conn, :create)
    |> response_with(conn)
  end

  def update(conn, params) do
    Page.changeset(%Perseids.Page{}, prepare_params(conn, params))
    |> valid_changeset?
    |> do_action(conn, :update)
    |> response_with(conn)
  end

  def destroy(conn, params) do
    Page.destroy(params, conn.assigns.lang)
    json(conn, :ok)
  end

  defp valid_changeset?(changeset) do
    {changeset.valid?, changeset}
  end

  defp do_action({true, changeset}, _conn, :create), do: Page.create(changeset.changes)
  defp do_action({true, changeset}, _conn, :update), do: Page.update(changeset.changes)
  defp do_action({false, changeset}, conn, _action), do: render conn |> put_status(422), "errors.json", changeset: changeset

  defp response_with({:error, reason}, conn), do: conn |> put_status(422) |> json(reason)
  defp response_with({:ok, page}, conn), do: render conn, "page.json", page: page
  defp response_with(page, conn), do: render conn, "page.json", page: page

  defp prepare_params(conn, params) do
    params
    |> Map.put_new("lang", conn.assigns.lang)
  end
end
