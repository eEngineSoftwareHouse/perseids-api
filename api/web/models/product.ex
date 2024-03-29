defmodule Perseids.Product do
  use Perseids.Web, :model

  @collection_name "products"
  @filterable_params ["category_ids", "color","pattern"]
  
  def find(opts, group_id, wholesale) do
    case Mongo.command(:mongo, %{"eval" => prepare_mongo_query(opts, group_id, wholesale)}) do
      {:ok, return} -> mongo_return(return["retval"], group_id)
      er -> IO.inspect(er); raise "Mongo custom command error"
    end
  end

  def find_one(group_id, [{:url_key, _source_id} | _tail] = options), do: find_one_with(options, group_id)
  def find_one(group_id, [{:source_id, _source_id} | _tail] = options), do: find_one_with(options, group_id)
  def find_one([{:url_key, _source_id} | _tail] = options), do: find_one_with(options)
  def find_one([{:source_id, _source_id} | _tail] = options), do: find_one_with(options)

  defp find_one_with(options, group_id) do
    @collection_name
    |> ORMongo.find_with_lang(options)
    |> item_response(group_id)
  end

  defp find_one_with(options) do
    @collection_name
    |> ORMongo.find_with_lang(options)
    |> item_response
  end

  defp prepare_mongo_query(opts, group_id, wholesale) do
    "productFilter("
      <> ( if group_id do group_id else "undefined" end) <> ","
      <> map_to_key_value_pair_json(opts[:filter]) <> ","
      <> Poison.encode!(@filterable_params) <> ","
      <> map_to_key_value_pair_json(opts[:options][:projection]) <> ","
      <> (nil_to_null_string(opts[:keywords]) |> escape_value) <> ","
      <> "\"" <> (opts[:lang] |> escape_value) <> "\","
      <> if wholesale do "1" else "0" end  <> "," # if true sorting products by name
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

  defp item_response([]), do: nil

  defp item_response(product) do
    product |> List.first
  end

  defp item_response([], _group_id), do: nil
  
  defp item_response(product, group_id) do
    product
    |> List.first
    |> group_price([], group_id)
  end

  defp mongo_return(retval, nil), do: retval

  defp mongo_return(retval, group_id) do
    retval
    |> Map.put("products", retval["products"] |> Enum.reduce([], &list_swap_group_price(&1, &2, group_id)) |> Enum.reverse)
  end

  defp list_swap_group_price(product, products_list, group_id) do 
    [ group_price(product, products_list, group_id) | products_list ] 
  end

  defp group_price(elem, _acc, group_id) do 
    elem 
    |> Map.put("variants", elem["variants"] |> Enum.reduce([], &single_swap_group_price(&1, &2, group_id)))
  end

  defp single_swap_group_price(variant, variant_list, group_id) do
    case variant["groups_prices"][group_id] do
      nil -> [variant | variant_list]
      group_price -> [ Map.put(variant, "netto_price", group_price) | variant_list ]
    end
  end

  def product_qty_update(%{ "count" => count, "id" => id, "variant_id" => variant_id }, lang) do
    variants = 
      Perseids.Product.find_one(source_id: id, lang: lang)["variants"]
      |> Enum.reduce([], &(update_variant_qty(&1["source_id"], variant_id, count, &1, &2)))
    Perseids.Product.update_product(%{"source_id" => id}, %{"variants" => variants}, lang)
  end

  def update_variant_qty(id, id, count, variant, acc), do: acc ++ [ Map.put(variant, "quantity", variant["quantity"] - count) ]
  def update_variant_qty(_id, _variant_id, _count,  variant, acc), do: acc ++ [ variant ]

  def update_product(filter, new_value, lang, upsert \\ false) do
    lang <> "_" <> @collection_name
    |> ORMongo.update_one(filter, new_value, upsert: upsert)
  end

end
