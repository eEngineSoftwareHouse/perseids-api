defmodule Perseids.BannerController do
  use Perseids.Web, :controller
  
  alias Perseids.Banner

  def index(conn, params) do
    banners = Helpers.to_keyword_list(params)
    |> ORMongo.set_language(conn)
    |> Banner.find

    render conn, "index.json", banners: banners
  end

  def create(conn, %{"img" => image_base64} = params) do
    changeset = Banner.changeset(%Perseids.Banner{}, prepare_params(conn, params))

    if changeset.valid? do
      render conn, "index.json", banners: Banner.update(changeset.changes)
    else
      render conn, "errors.json", changeset: changeset
    end
  end

  defp prepare_params(conn, params) do
    params
    |> Map.put_new("lang", conn.assigns.lang)
  end
end