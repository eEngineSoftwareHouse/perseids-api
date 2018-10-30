defmodule Perseids.ServiceController do
  use Perseids.Web, :controller
  alias Perseids.Category

  def newsletter(conn, params) do 
    body = 
      params 
      |> Map.put_new("list", conn.assigns.fresh_mail_list_id)
      |> Map.put_new("state", 1)
      |> Map.put_new("confirm", 0)

    { status, response } = FreshMail.save_email(body)

    conn
    |> put_status(status)
    |> json(response)
  end

  def show(%{assigns: %{lang: lang}} = conn, %{"source_id" => source_id}) do
    render conn, "category.json", category: Category.find_one(source_id: source_id, lang: lang)
  end
end
