defmodule Perseids.Product do
  use Perseids.Web, :model

  @collection_name "products"
  @filterable_params ["category_ids", "color","pattern"]

  def find(opts, group_id) do
    case Mongo.command(:mongo, %{"eval" => prepare_mongo_query(opts, group_id)}) do
      {:ok, return} -> mongo_return(return["retval"], group_id)
      er -> IO.inspect(er); raise "Mongo custom command error"
    end
  end

  def find_one(group_id, [{:url_key, _source_id} | _tail] = options), do: find_one_with(options, group_id)
  def find_one(group_id, [{:source_id, _source_id} | _tail] = options), do: find_one_with(options, group_id)

  defp find_one_with(options, group_id) do
    @collection_name
    |> ORMongo.find_with_lang(options)
    |> item_response(group_id)
  end

  defp prepare_mongo_query(opts, group_id) do
    "productFilter("
      <> ( if group_id do group_id else "undefined" end) <> ","
      <> map_to_key_value_pair_json(opts[:filter]) <> ","
      <> Poison.encode!(@filterable_params) <> ","
      <> map_to_key_value_pair_json(opts[:options][:projection]) <> ","
      <> (nil_to_null_string(opts[:keywords]) |> escape_value) <> ","
      <> "\"" <> (opts[:lang] |> escape_value) <> "\","
      <> (Integer.to_string(opts[:options][:skip]) |> escape_value) <> ","
      <> (Integer.to_string(opts[:options][:limit]) |> escape_value) <> ","
      <> Integer.to_string(1) <> ");" # sorting setting: 1 is ascending, -1 descending
  end

  defp escape_value(value), do: value |> String.replace("'", "") |> String.replace("\"", "")

  defp nil_to_null_string(var) do
    case var do
      nil -> "null"
      _ -> "\"" <> var <> "\""
    end
  end

  defp map_to_key_value_pair_json(map) do
    case map do
      nil -> "[]"
      _ -> map
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

  defp item_response(product, group_id) do
    variants = product
    |> List.first
    |> group_price([], group_id)
  end

  defp mongo_return(retval, nil), do: retval

  defp mongo_return(retval, group_id) do
    retval
    |> Map.put("products", retval["products"] |> Enum.reduce([], fn(x,acc) -> [group_price(x, acc, group_id) | acc] end) |> Enum.reverse)
  end

  defp group_price(elem, acc, group_id) do
    elem
    |> Map.put("variants", elem["variants"] |> Enum.reduce([], fn(x, acc) -> (if x["groups_prices"][group_id] do [Map.put(x, "price", x["groups_prices"][group_id]) | acc ] else [x | acc] end) end))
  end
end
