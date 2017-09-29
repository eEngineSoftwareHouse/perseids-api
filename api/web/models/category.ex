defmodule Perseids.Category do
  use Perseids.Web, :model

  @collection_name "categories"

  def find([_] = opts) do
    @collection_name
    |> ORMongo.find_with_lang(opts)
    |> list_response
  end


  def find_one([{:source_id, _source_id} | _tail] = options) do
    @collection_name
    |> ORMongo.find_with_lang(options)
    |> item_response
  end

  def list_response(categories) do
    categories
  end

  def item_response(categories) do
    categories |> List.first
  end
end
