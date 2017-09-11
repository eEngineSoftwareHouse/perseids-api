defmodule Perseids.Product do
  use Perseids.Web, :model

  @collection_name "products"
  @filterable_params ["category_ids", "color","size"]

  # TODO przerobić wyciąganie filtrów na listing na wykorzystujące współbieżność
  # zmienne "available_params" w funkcjach "find"

  def find([{:keywords, keywords}, _] = opts) do
     available_params = extract_filters(@filterable_params, %{"keywords" => [keywords]}, %{})
#    available_params = []
    response(opts, available_params, opts)
  end

  def find([{:filter, filters}, _] = opts) do
     available_params = extract_filters(@filterable_params, filters, %{})
#    available_params = []
    response(opts, available_params, filters)
  end

  def find([_] = opts) do
     available_params = extract_filters(@filterable_params, %{}, %{})
#    available_params = []
    response(opts |> Keyword.put_new(:filter, %{}), available_params, %{})
  end

  def response(opts, available_params, count_opts) do
    @collection_name
    |> ORMongo.find(opts)
    |> list_response(available_params, count_opts)
  end

  def find_one(source_id) do
    @collection_name
    |> ORMongo.find([source_id: source_id])
    |> item_response
  end


  def list_response(products, params \\ [], filter \\ %{}) do
    %{
      "products" => products,
      "params" => [],#params,
      "count" => ORMongo.count(@collection_name, filter)
    }
  end

  def item_response(product) do
    product |> List.first
  end

  defp extract_filters(filterable_params, nil, acc) do
    extract_filters(filterable_params, %{}, acc)
  end

  defp extract_filters([current_param | remaining_params], conditions, acc) do
#    values = case current_param do
#      "category_ids" ->  
#        where = Map.drop(conditions, [current_param])
#        ORMongo.find(@collection_name, filter: where)
#        |> Enum.map(fn(e) -> e["categories"] end)
#        |> List.flatten
#        |> Enum.map(fn(e) -> e["id"] end)
#      _ -> 
#        where = Map.drop(conditions, ["params." <> current_param])
#        ORMongo.find(@collection_name, filter: where)
#        |> Enum.map(fn(e) -> e["params"][current_param] end)
#        |> List.flatten
#    end
#    |> Enum.uniq
#    |> Enum.reject(&is_nil/1)
#    
#    acc = Map.put_new(acc, current_param, values)
#
#    extract_filters(remaining_params, conditions, acc)
#   
#### Temporarly disable filters
    []
  end

  defp extract_filters([], _conditions, acc) do
    acc
  end
end
