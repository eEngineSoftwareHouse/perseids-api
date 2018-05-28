defmodule Perseids.Page do
  use Perseids.Web, :model

  @collection_name "pages"

  schema @collection_name do
   field :slug,                    :string
   field :title,                   :string
   field :content,                 :string
   field :seo_title,               :string
   field :seo_description,         :string
   field :position,                :string
   field :active,                  :boolean
  end

  def changeset(page, params \\ %{}) do
    page
    |> cast(params, [:id, :slug, :title, :content, :seo_title, :seo_description, :position, :active])
    |> validate_required([:slug, :title, :content, :seo_title, :seo_description, :position, :active])
    # |> validate_uniqueness([:slug, :title, :position]) # TODO
  end

  def create(params, lang) do
    lang <> "_" <> @collection_name
    |> ORMongo.insert_one(params)
    |> item_response
  end

  def update(%{id: id} = params, lang) do
    lang <> "_" <> @collection_name
    |> ORMongo.find_one_and_update(%{"_id" => BSON.ObjectId.decode!(id)}, params |> Map.drop([:id]), upsert: true)
  end

  def destroy(%{"id" => id} = _params, lang) do
    lang <> "_" <> @collection_name
    |> ORMongo.destroy_by_id([_id: id])
  end

  def find([_] = opts) do
    @collection_name
    |> ORMongo.find_with_lang(opts)
    |> list_response
  end

  def find_one([{:slug, _slug} | _tail] = options) do
    @collection_name
    |> ORMongo.find_with_lang(options)
    |> item_response
  end

  def list_response(pages) do
    pages
  end

  def item_response(pages) do
    pages |> List.first
  end
end
