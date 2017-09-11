defmodule Perseids.Category do
  use Perseids.Web, :model

  @collection_name "categories"

  def find(opts \\ [filter: %{}]) do
    @collection_name
    |> ORMongo.find(opts)
    |> list_response
  end

  def find_one(source_id) do
    @collection_name
    |> ORMongo.find([source_id: source_id])
    |> item_response
  end

  def list_response(categories) do
    categories
  end

  def item_response(categories) do
    categories |> List.first
  end
end
