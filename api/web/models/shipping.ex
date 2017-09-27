defmodule Perseids.Shipping do
  use Perseids.Web, :model

  @collection_name "shipping"

  def find(opts \\ [filter: %{}]) do
    @collection_name
    |> ORMongo.find_with_lang(opts)
    |> list_response
  end

  def find_one([{:source_id, source_id}, {:lang, lang}]) do
    @collection_name
    |> ORMongo.find_with_lang([source_id: source_id, lang: lang])
    |> item_response
  end

  def list_response(list) do
    list
  end

  def item_response(list) do
    list |> List.first
  end
end
