defmodule Perseids.Product do
  use Perseids.Web, :model

  @collection_name "products"
  @filterable_params ["category_ids", "color","size"]

  # TODO przerobić wyciąganie filtrów na listing na wykorzystujące współbieżność
  # zmienne "available_params" w funkcjach "find"

  def find([{:lang, lang} | tail] = opts) do
    find(lang, tail)
  end

  def find(lang, [{:keywords, keywords}, _] = opts) do
    #  available_params = extract_filters(@filterable_params, %{"keywords" => [keywords]}, %{}, lang)
    available_params = [] #### Temporarly disable filters
    lang |> response(opts, available_params, opts)
  end

  def find(lang, [{:filter, filters}, _] = opts) do
    #  available_params = extract_filters(@filterable_params, filters, %{}, lang)
    available_params = [] #### Temporarly disable filters
    lang |> response(opts, available_params, filters)
  end

  def find(lang, [_] = opts) do
    #  available_params = extract_filters(@filterable_params, %{}, %{}, lang)
    available_params = [] #### Temporarly disable filters
    lang |> response(opts |> Keyword.put_new(:filter, %{}), available_params, %{})
  end

  def response(lang, opts, available_params, count_opts) do
    ORMongo.collection_name(lang, @collection_name)
    |> ORMongo.find(opts)
    |> list_response(available_params, count_opts)
  end

  def find_one(lang, source_id) do
    ORMongo.collection_name(lang, @collection_name)
    |> ORMongo.find([source_id: source_id])
    |> item_response
  end


  def list_response(products, params \\ [], filter \\ %{}) do
    %{
      "products" => products,
      "params" => params,
      "count" => ORMongo.count(@collection_name, filter)
    }
  end

  def item_response(product) do
    product |> List.first
  end

  defp extract_filters(filterable_params, nil, acc, lang) do
    extract_filters(filterable_params, %{}, acc, lang)
  end

  defp extract_filters([current_param | remaining_params], conditions, acc, lang) do
    values = case current_param do
     "category_ids" ->
       where = Map.drop(conditions, [current_param])
       ORMongo.collection_name(lang, @collection_name)
       |> ORMongo.find(filter: where)
       |> Enum.map(fn(e) -> e["categories"] end)
       |> List.flatten
       |> Enum.map(fn(e) -> e["id"] end)
     _ ->
       where = Map.drop(conditions, ["params." <> current_param])
       ORMongo.collection_name(lang, @collection_name)
       |> ORMongo.find(filter: where)
       |> Enum.map(fn(e) -> e["params"][current_param] end)
       |> List.flatten
    end
    |> Enum.uniq
    |> Enum.reject(&is_nil/1)

    acc = Map.put_new(acc, current_param, values)

    extract_filters(remaining_params, conditions, acc, lang)
  end

  defp extract_filters([], _conditions, acc, lang) do
    acc
  end
end
