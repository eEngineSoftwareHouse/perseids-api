defmodule Perseids.Product do
  use Perseids.Web, :model

  @collection_name "products"
  @filterable_params ["category_ids", "color","size"]

  def find(opts) do
    case Mongo.command(:mongo, %{"eval" => prepare_mongo_query(opts)}) do
      {:ok, return} -> return["retval"]
      er -> IO.inspect(er); raise "Mongo custom command error"
    end
  end

  def find_one([{:source_id, _source_id} | _tail] = options) do
    @collection_name
    |> ORMongo.find_with_lang(options)
    |> item_response
  end

  defp prepare_mongo_query(opts) do
    "productFilter("
      <> filters_to_key_value_pair_json(opts[:filter]) <> ","
      <> Poison.encode!(@filterable_params) <> ","
      <> nil_to_null_string(opts[:keywords]) <> ","
      <> "\"" <> opts[:lang] <> "\","
      <> Integer.to_string(opts[:options][:skip]) <> ","
      <> Integer.to_string(opts[:options][:limit]) <> ");"
  end

  defp nil_to_null_string(var) do
    case var do
      nil -> "null"
      _ -> "\"" <> var <> "\""
    end
  end

  defp filters_to_key_value_pair_json(filters) do
    case filters do
      nil -> "[]"
      _ -> filters
            |> Enum.to_list
            |> Enum.reduce([], &name_content_maps(&1, &2))
            |> Poison.encode!
    end
  end

  defp name_content_maps(elem, acc) do
    {name, content} = elem
    acc ++  [%{name: name, content: content}]
  end

  defp item_response(product) do
    product |> List.first
  end
end
