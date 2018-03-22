defmodule Perseids.Session do
  use Perseids.Web, :model

  @collection_name "sessions"

  schema @collection_name do
   field :magento_token, :string
   field :customer_id,   :integer
   field :wholesale,     :boolean
   field :group_id,      :integer
   field :admin,         :boolean
   field :tax_rate,      :float
  end

  def changeset(order, params \\ %{}) do
   order
     |> cast(params, [:magento_token, :customer_id, :wholesale, :group_id, :admin, :tax_rate])
     |> validate_required([:magento_token])
  end

  def create(params) do
    @collection_name
    |> ORMongo.insert_one(params)
    |> item_response
  end

  def destroy(id) do
    @collection_name
    |> ORMongo.destroy_by_id([_id: id])
  end

  def find(opts \\ [filter: %{}]) do
    @collection_name
    |> ORMongo.find(opts)
    |> list_response
  end

  def find_one(id) do
    @collection_name
    |> ORMongo.find([_id: id])
    |> item_response
  end

  def list_response(list) do
    list
  end

  def item_response(list) do
    list |> List.first
  end
end
