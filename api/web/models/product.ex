defmodule Perseids.Product do
  use Perseids.Web, :model

  @collection_name "products"
  @filterable_params ["category_ids", "color","size"]

  # TODO filters need hard optimization, so they're disabled for now

  def find([{:keywords, keywords} | _] = opts) do
    #  available_params = extract_filters(@filterable_params, %{"keywords" => [keywords]}, %{}, opts[:lang])
    available_params = [] #### Temporarly disable filters
    response(opts, available_params, opts)
  end

  def find([{:filter, filters} | _] = opts) do
    #  available_params = extract_filters(@filterable_params, filters, %{}, opts[:lang])
    available_params = [] #### Temporarly disable filters
    response(opts, available_params, filters)
  end

  def find([_] = opts) do
    #  available_params = extract_filters(@filterable_params, %{}, %{}, opts[:lang])
    available_params = [] #### Temporarly disable filters
    response(opts |> Keyword.put_new(:filter, %{}), available_params, %{})
  end

  def response(opts, available_params, count_opts) do
    @collection_name
    |> ORMongo.find_with_lang(opts)
    |> list_response(available_params, count_opts, opts[:lang])
  end

  def find_one([{:source_id, source_id} | _tail] = options) do
    @collection_name
    |> ORMongo.find_with_lang(options)
    |> item_response
  end


  def list_response(products, params \\ [], filter \\ %{}, lang) do
    %{
      "products" => products,
      "params" => params,
      "count" => ORMongo.count(lang <> "_" <> @collection_name, filter)
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
       @collection_name
       |> ORMongo.find_with_lang(filter: where, lang: lang)
       |> Enum.map(fn(e) -> e["categories"] end)
       |> List.flatten
       |> Enum.map(fn(e) -> e["id"] end)
     _ ->
       where = Map.drop(conditions, ["params." <> current_param])
       @collection_name
       |> ORMongo.find_with_lang(filter: where, lang: lang)
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
