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
    render conn, "page.json", page: Page.find_one(slug: slug, lang: lang)
  end

  def create(conn, params) do
    changeset = 
      Page.changeset(%Perseids.Page{}, params)
      |> valid_changeset?
      |> do_action(conn, :create)
      |> response_with(conn)
  end

  def update(conn, params) do
    changeset = 
      Page.changeset(%Perseids.Page{}, params)
      |> valid_changeset?
      |> do_action(conn, :update)
      |> response_with(conn)
  end

  def destroy(conn, params) do
    Page.destroy(params, conn.assigns.lang)
    json(conn, :ok)
  end

  def valid_changeset?(changeset) do
    {changeset.valid?, changeset}
  end

  def do_action({false, changeset}, conn, _action), do: render conn, "errors.json", changeset: changeset
  def do_action({true, changeset}, conn, :create), do: Page.create(changeset.changes, conn.assigns.lang)
  def do_action({true, changeset}, conn, :update), do: Page.update(changeset.changes, conn.assigns.lang)

  def response_with({:error, reason}, conn), do: conn |> put_status(422) |> json(reason)
  def response_with({:ok, page}, conn), do: render conn, "page.json", page: page
  def response_with(page, conn), do: render conn, "page.json", page: page
end
