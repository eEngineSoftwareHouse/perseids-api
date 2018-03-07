defmodule Perseids.ProductResolver do
  alias Perseids.Product

  def all(_args, _info) do
    {:ok, Product.find([filter: %{}], 1)["products"] |> Helpers.atomize_keys }
  end

end
