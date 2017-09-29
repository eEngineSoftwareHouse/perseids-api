defmodule Perseids.Page do
  use Perseids.Web, :model

  @collection_name "pages"

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
