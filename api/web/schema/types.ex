defmodule Perseids.Schema.Types do
  use Absinthe.Schema.Notation

  object :product do
    field :name, :string, description: "Product name"
    field :description, :string, description: "Product description"
    field :price, :string, description: "Product price"
    field :vat, :string, description: "VAT tax value"
    field :code, :string, description: "Product code"
    # field :params, :map, description: "Product pictures URLs"
    # field :pictures, :map, description: "Product pictures URLs"
    # field :categories, :map, description: "Product categories"
    field :source_id, :string, description: "Origin source_id"
    field :variant, :string, description: "Origin variant_id"
  end
end
