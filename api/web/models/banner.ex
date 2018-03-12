defmodule Perseids.Banner do
  use Perseids.Web, :model

  @collection_name "banners"

  schema @collection_name do
   field :url,                    :string
   field :alt,                    :string
   field :order,                  :integer
   field :grid,                   :string
   field :size,                   :string
   field :image,                  :string
   field :lang,                   :string
  end

  def changeset(banner, params \\ %{}) do
    banner
    |> cast(params, [:url, :alt, :order, :grid, :image, :lang, :size])
    |> validate_required([:url, :alt, :order, :grid, :image, :size])
  end

  def update(%{grid: grid, order: order, image: image_base64, lang: lang} = params) do
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
