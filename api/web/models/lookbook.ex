defmodule Perseids.Lookbook do
  use Perseids.Web, :model

  @collection_name "lookbooks"

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

  def list_response(lookbooks) do
    lookbooks
  end

  def item_response(lookbooks) do
    lookbooks |> List.first
  end
end
