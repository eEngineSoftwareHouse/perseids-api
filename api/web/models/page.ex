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
   field :lang,                    :string
   field :active,                  :boolean
  end

  def changeset(page, params \\ %{}) do
    page
    |> cast(params, [:id, :lang, :slug, :title, :content, :seo_title, :seo_description, :position, :active])
    |> validate_required([:slug, :title, :content, :seo_title, :seo_description, :position, :active])
    |> validate_uniqueness([:slug, :title], params["lang"])
  end
  
  def create(%{lang: lang} = params) do
    params = 
      params
      |> Map.drop([:lang])

    lang <> "_" <> @collection_name
    |> ORMongo.insert_one(params)
    |> item_response
  end

  def update(%{id: id, lang: lang} = params) do
    params = 
      params
      |> Map.drop([:lang, :id])

    lang <> "_" <> @collection_name
    |> ORMongo.find_one_and_update(%{"_id" => BSON.ObjectId.decode!(id)}, params, upsert: true)
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

  ### VALIDATIONS ###

  def validate_uniqueness(changeset, fields, lang) do
    [lang: lang]
    |> Perseids.Page.find
    |> Enum.filter(&(&1["_id"] |> BSON.ObjectId.encode! != get_field(changeset, :id)))
    |> Enum.reduce(changeset, &(validate_single_page(&2, fields, &1)))
  end

  defp validate_single_page(changeset, [], _page), do: changeset
  defp validate_single_page(changeset, [head | tail], page) do
    field = get_field(changeset, head)
    head = head |> Atom.to_string

    page 
    |> Map.fetch!(head)
    |> validate_uniqueness_of_field(field, head, changeset)
    |> validate_single_page(tail, page)
  end

  defp validate_uniqueness_of_field(value, value, key, changeset), do: add_error(changeset, key, "#{key} with value #{value} already exist!")
  defp validate_uniqueness_of_field(_value, _another, _key, changeset), do: changeset
end
