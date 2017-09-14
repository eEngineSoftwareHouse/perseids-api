defmodule Helpers do

  def atomize_keys(nil), do: nil

  def atomize_keys(struct = %{__struct__: _}) do
    struct
  end

  def atomize_keys(map = %{}) do
    map
    |> Enum.map(fn {k, v} -> {String.to_atom(k), atomize_keys(v)} end)
    |> Enum.into(%{})
  end

  def atomize_keys([head | rest]) do
    [atomize_keys(head) | atomize_keys(rest)]
  end

  def atomize_keys(other) do
    other
  end

  def to_keyword_list(dict) do
    Enum.map(dict, fn({key, value}) ->
      case key do
        "limit" ->
          {String.to_atom(key), String.to_integer(value)}
        _ ->
          {String.to_atom(key), value}
      end
    end)
  end
end
