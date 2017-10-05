defmodule Perseids.LookbookController do
  use Perseids.Web, :controller
  alias Perseids.Lookbook

  def index(conn, params) do
    lookbooks = Helpers.to_keyword_list(params)
    |> ORMongo.set_language(conn)
    |> Lookbook.find

    render conn, "index.json", lookbooks: lookbooks
  end

  def show(%{assigns: %{lang: lang}} = conn, %{"source_id" => source_id}) do
    render conn, "lookbook.json", lookbook: Lookbook.find_one(source_id: source_id, lang: lang)
  end
end
