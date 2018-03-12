defmodule Perseids.Banner do
  use Perseids.Web, :model

  @collection_name "banners"

  schema @collection_name do
   field :url,                  :string
   field :alt,                  :string
   field :order,                :integer
   field :grid,                 :string
   field :img,                  :string
   field :lang,                 :string
  end

  def changeset(order, params \\ %{}) do
    order
    |> cast(params, [:url, :alt, :order, :grid, :img, :lang])
    |> validate_required([:url, :alt, :order, :grid, :img])
  end

  def update(%{grid: grid, order: order, img: image_base64, lang: lang} = params) do
    params = params
    |> Map.drop([:lang])
    |> Map.put_new(:image_url, Perseids.AssetStore.upload_image(image_base64))
    
    lang <> "_" <> @collection_name
    |> ORMongo.update_one(%{"grid" => grid, "order" => order}, params, upsert: true)
    
    find(lang: lang)
  end

  def find([_] = opts) do
    @collection_name
    |> ORMongo.find_with_lang(opts)
    |> list_response
  end

  def list_response(banners) do
    banners
  end
end
