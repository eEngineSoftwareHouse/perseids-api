defmodule Perseids.ServiceController do
  use Perseids.Web, :controller
  alias Perseids.Category

  def newsletter(conn, params) do 
    body = params |> Map.put_new("campaign", %{"campaignId" => conn.assigns.get_response_campaign_id})
    { status, response } = GetResponse.save_email(body)

    conn
    |> put_status(status)
    |> json(response)
  end
  
  def show(%{assigns: %{lang: lang}} = conn, %{"source_id" => source_id}) do
    render conn, "category.json", category: Category.find_one(source_id: source_id, lang: lang)
  end
end
