defmodule Perseids.Navbar do
  use Perseids.Web, :model

  @collection_name "navbars"

  schema @collection_name do
   field :slug,                    :string
   field :title,                   :string
   field :lang,                    :string
   field :order,                   :integer
  end

  def changeset(navbar, params \\ %{}) do
    navbar
    |> cast(params, [:title, :slug, :order, :lang])
    |> validate_number(:order, greater_than_or_equal_to: 0, less_than_or_equal_to: 5)
    |> validate_required([:slug, :title, :order])
  end

  def update(%{order: order, lang: lang} = params) do
    params = 
      params
      |> Map.drop([:lang])

    lang <> "_" <> @collection_name
    |> ORMongo.find_one_and_update(%{"order" => order}, params, upsert: true)

    find(lang: lang)
  end

  def find([_] = opts) do
    @collection_name
    |> ORMongo.find_with_lang(opts)
    |> list_response
  end

  def list_response(pages) do
    pages
  end
end
