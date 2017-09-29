defmodule Perseids.ServiceController do
  use Perseids.Web, :controller
  alias Perseids.Category

  def newsletter(conn, params), do: json(conn, GetResponse.save_email(params))
  
  def show(%{assigns: %{lang: lang}} = conn, %{"source_id" => source_id}) do
    render conn, "category.json", category: Category.find_one(source_id: source_id, lang: lang)
  end
end
