defmodule Perseids.Pagination do
  def prepare_params(params) do
    params = to_keyword_list(params)

    page = case params[:page] do
      nil -> 1
      _ -> params[:page]
    end

    per_page = case params[:per_page] do
      nil -> 12
      _ -> params[:per_page]
    end

    skip = (page - 1) * per_page

    params_without_pagination = Keyword.drop(params, [:page, :per_page, :select])
    prepared_params = case params_without_pagination |> Enum.count do
      0 -> [filter: %{}]
      _ -> params_without_pagination
    end

    prepared_params ++ [options: [skip: (page - 1) * per_page, limit: per_page, projection: params[:select] |> projection_params]]
  end

  # def add_language(params, conn) do
  #   params
  #   |> Keyword.put_new(:lang, conn.assigns[:lang])
  # end

  defp projection_params(select) do
    case select do
      nil -> [
        title: 1,
        description: 1,
        price: 1,
        params: 1,
        variants: 1,
        source_id: 1,
        categories: 1,
        params: 1,
        name: 1
      ]
      _ -> String.split(select, ",") |> Enum.map(fn(v) -> {String.to_atom(v), 1} end)
    end
  end

  defp to_keyword_list(dict) do
    Enum.map(dict, fn({key, value}) ->
      case key do
        "page" ->
          {String.to_atom(key), String.to_integer(value)}
        "per_page" ->
          {String.to_atom(key), String.to_integer(value)}
        _ ->
          {String.to_atom(key), value}
      end
    end)
  end

  # z poniższych funkcji korzysta paginacja zamówień klienta
  # TODO zaadaptować rozwiązanie z produktów)

  def paginate_collection(collection, params) do
    config = maybe_put_default_config(Helpers.atomize_keys(params))
    Scrivener.paginate(collection, config)
  end

  defp maybe_put_default_config(%{page: page_number} = _params) do
    %Scrivener.Config{page_number: String.to_integer(page_number), page_size: 12}
  end

  defp maybe_put_default_config(_params) do
    %Scrivener.Config{page_number: 1, page_size: 12}
  end
end
