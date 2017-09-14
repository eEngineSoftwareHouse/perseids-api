defmodule Perseids.CategoryController do
  use Perseids.Web, :controller
  alias Perseids.Category

  def index(conn, params) do
    categories = to_keyword_list(params)
    |> ORMongo.set_language(conn)
    |> Category.find

    render conn, "index.json", categories: categories
  end

  def show(%{assigns: %{lang: lang}} = conn, %{"source_id" => source_id}) do
    render conn, "category.json", category: Category.find_one(source_id: source_id, lang: lang)
  end

  defp to_keyword_list(dict) do
    Enum.map(dict, fn({key, value}) ->
      case key do
        "limit" ->
          {String.to_atom(key), String.to_integer(value)}
        _ ->
          {String.to_atom(key), value}
      end
    end)
  end
end