defmodule ORMongo do
  # Workaround of bug in mongodb driver, which makes impossible to call Enum.to_list on cursor with limit: 0
  @default_limit 10000000

  def find(collection, filter: filter, options: options) do
    mongo_find(collection, filter, options)
  end

  def find(collection, filter: filter, limit: limit) do
    mongo_find(collection, filter, limit: limit)
  end

  def find(collection, filter: filter) do
    mongo_find(collection, filter, limit: @default_limit)
  end

  def find(collection, []) do
    mongo_find(collection, %{}, limit: @default_limit)
  end

  def find(collection, limit: limit) do
    mongo_find(collection, %{}, limit: limit)
  end

  def find(collection, keywords: phrase, options: options) do
    mongo_search(collection, %{"$text" => %{"$search" => phrase}}, options)
  end

  def find(collection, keywords: phrase, limit: limit) do
    mongo_search(collection, %{"$text" => %{"$search" => phrase}}, limit: limit)
  end

  def find(collection, keywords: phrase) do
    mongo_search(collection, %{"$text" => %{"$search" => phrase}}, [limit: @default_limit])
  end

  def find(collection, _id: id) do
    mongo_find_one_by_id(collection, id)
  end

  def find(collection, source_id: source_id) do
    mongo_find_one_by_field(collection, %{ source_id: source_id })
  end

  def count(collection, [{:keywords, keywords}, _]) do
    Mongo.count(:mongo, collection, %{"$text" => %{"$search" => keywords}})
    |> elem(1)
  end

  def count(collection, filter) do
    case filter do
      nil -> Mongo.count(:mongo, collection, %{})
      _ -> Mongo.count(:mongo, collection, prepare_filters(filter))
    end
    |> elem(1)
  end

  def destroy_by_id(collection, _id: id) do
    Mongo.find_one_and_delete(:mongo, collection, %{_id: BSON.ObjectId.decode!(id)})
  end

  def insert_one(collection, params) do
    params = Map.put_new(params, :created_at, DateTime.utc_now |> DateTime.to_string)
    {:ok, id} = Mongo.insert_one(:mongo, collection, params)
    Mongo.find(:mongo, collection, %{_id: id.inserted_id})
    |> result
  end

  defp search_options(options) do
    options
    |> Keyword.put_new(:limit, 0)
    |> Keyword.update(:projection, [], &add_search_score/1) # you have to have $meta in your projection while using $text search
    |> Keyword.update(:sort, [], &add_search_score/1)
  end

  defp add_search_score(options) do
    options
    |> Keyword.put_new(:score, %{"$meta" => "textScore"})
  end

  # Sample filter map which is passed to this function may look like this:
  # %{"params.colour" => ["Beige"], "params.size" => ["L", "XL"]}

  # So we want to ask DB as follows:
  # Mongo.find(:mongo, "products", %{"$and" => [%{"params.colour" => %{ "$in" => ["Beige"]}}, %{"params.size" => %{ "$in" => ["L", "XL"]}}]})

  defp prepare_filters(filters) do
    case Enum.count(Map.keys(filters)) do
      0 ->
        %{}
      _ ->
        %{ "$and" => Map.keys(filters)
        |> Enum.reduce([], fn(key, acc) -> acc ++ [%{ key => %{"$in" => filters[key]}}] end) }
    end
  end

  defp mongo_search(collection, query, options) do
    options = options |> search_options
    Mongo.find(:mongo, collection, query, options)
    |> result
  end

  defp mongo_find(collection, filters, options) do
    filters = prepare_filters(filters)
    Mongo.find(:mongo, collection, filters, options)
    |> result
  end

  defp mongo_find_one_by_id(collection, id) do
    Mongo.find(:mongo, collection, %{_id: BSON.ObjectId.decode!(id)})
    |> result
  end

  defp mongo_find_one_by_field(collection, field) do
    Mongo.find(:mongo, collection, field)
    |> result
  end

  defp result(cursor) do
    cursor
    |> Enum.to_list
  end
end
