defmodule Perseids.Schema do
  use Absinthe.Schema
  import_types Perseids.Schema.Types

  query do
    @desc "Get products"
    field :products, type: list_of(:product) do
      resolve &Perseids.ProductResolver.all/2
    end
  end
end
