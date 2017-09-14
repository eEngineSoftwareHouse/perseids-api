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

end
