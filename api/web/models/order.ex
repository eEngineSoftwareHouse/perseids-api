defmodule Perseids.Order do
  use Perseids.Web, :model

  @collection_name "orders"

  schema @collection_name do
   field :products,     {:array, :map}
   field :payment,      :string
   field :shipping,     :string
   field :address,      :map
   field :created_at,   :string
   field :customer_id,  :integer
  end

  def changeset(order, params \\ %{}) do
   order
     |> cast(params, [:products, :payment, :shipping, :address, :created_at, :customer_id])
     |> validate_required([:products, :payment, :shipping, :address])
  end

  def create(params) do
    @collection_name
    |> ORMongo.insert_one(params)
    |> item_response
  end


  def delivery_options(opts \\ [filter: %{}]) do
    %{
      shipping: "shipping" |> ORMongo.find(opts) |> list_response,
      payment: "payment" |> ORMongo.find(opts) |> list_response
    }
  end

  def find(opts \\ [filter: %{}]) do
    @collection_name
    |> ORMongo.find(opts)
    |> list_response
  end

  def find_one(source_id) do
    @collection_name
    |> ORMongo.find([source_id: source_id])
    |> item_response
  end

  def list_response(list) do
    list
  end

  def item_response(list) do
    list |> List.first
  end
end
