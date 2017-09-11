defmodule Perseids.Param do
  use Perseids.Web, :model

  @collection_name "params"

  def find(filter \\ %{}, _limit \\ "20") do
    Mongo.find(:mongo, @collection_name, filter)
    |> Enum.to_list
  end

  def all(limit \\ "all") do
    find(%{}, limit)
  end
end
