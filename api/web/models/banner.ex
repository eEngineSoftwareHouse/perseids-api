defmodule Perseids.Banner do
  use Perseids.Web, :model

  @collection_name "banners"

  schema @collection_name do
   field :url,                    :string
   field :alt,                    :string
   field :order,                  :integer
   field :grid,                   :string
   field :size,                   :string
   field :base64,                 :string
   field :lang,                   :string
   field :image,                  :string
  end

  def changeset(banner, params \\ %{}) do
    banner
    |> cast(params, [:url, :alt, :order, :grid, :base64, :lang, :size, :image])
    |> validate_required([:url, :alt, :order, :grid, :base64, :size])
    |> save_image
  end

  def update(%{grid: grid, order: order, lang: lang} = params) do
    params = params
    |> Map.drop([:lang])
    # |> Map.put(:image, Perseids.AssetStore.upload_image(image_base64))
    
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

  def save_image(changeset) do
    case get_field(changeset, :base64) |> Perseids.AssetStore.upload_image do
      {:ok, image_url} -> changeset |> put_change(:image, image_url)
      {:error, reason} -> add_error(changeset, :base64, "Unable to save image on server, reason: #{reason}")
      _ -> add_error(changeset, :base64, "Unable to save image on server due to internal error. Check API logs.")
    end
  end
end
