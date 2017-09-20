defmodule Perseids.ServiceController do
  use Perseids.Web, :controller

  def newsletter(conn, params) do
    IO.puts "newsletter"
    IO.inspect params
    json(conn, GetResponse.save_email(params))
  end

  def show(%{assigns: %{lang: lang}} = conn, %{"source_id" => source_id}) do
    render conn, "category.json", category: Category.find_one(source_id: source_id, lang: lang)
  end
end
