defmodule Perseids.Product do
  use Perseids.Web, :model

  @collection_name "products"
  @filterable_params ["category_ids", "color","pattern"]

  def find(opts) do
    # exclude_giftboxes: If no categories.id filter is specified, return products only from root Default Category, 
    # to prevent displaying gift boxes with other products
    # case Mongo.command(:mongo, %{"eval" => exclude_giftboxes(opts) |> prepare_mongo_query }) do
    case Mongo.command(:mongo, %{"eval" => opts |> prepare_mongo_query }) do
      {:ok, return} -> return["retval"]
      er -> IO.inspect(er); raise "Mongo custom command error"
    end
  end

  def find_one([{:url_key, _source_id} | _tail] = options), do: find_one_with(options)
  def find_one([{:source_id, _source_id} | _tail] = options), do: find_one_with(options)

  defp find_one_with(options) do
    @collection_name
    |> ORMongo.find_with_lang(options)
    |> item_response
  end

  # def exclude_giftboxes([{:filter, filter}, {:options, options} | tail]),            do: exclude_giftboxes(filter, options, tail)
  # def exclude_giftboxes(%{"categories.id" => _category_id} = filter, options, tail), do: [ {:filter, filter}, {:options, options} | tail ]
  # def exclude_giftboxes(filter, options, tail),                                      do: [ {:filter, filter |> Map.put_new("categories.id", [default_category_id()])}, {:options, options} | tail ]

  defp prepare_mongo_query(opts) do
    "productFilter("
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

  # defp default_category_id, do: Application.get_env(:perseids, :magento)[:default_category_id]
end
