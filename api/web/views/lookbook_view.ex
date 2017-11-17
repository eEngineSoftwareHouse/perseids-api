defmodule Perseids.LookbookView do
  def render("index.json", %{lookbooks: lookbooks}) do
    Enum.map(lookbooks, &lookbook_json/1)
  end

  def render("lookbook.json", %{lookbook: lookbook}) do
    lookbook_json(lookbook)
  end

  defp lookbook_json(lookbook) do
    %{
      id: BSON.ObjectId.encode!(lookbook["_id"]),
      name: lookbook["name"],
      slug: lookbook["name"] |> String.downcase |> String.normalize(:nfd) |> String.replace(~r/[^A-z\s]/u, "") |> String.replace(~r/\s/, "-"),
      source_id: lookbook["source_id"],
      description: lookbook["description"],
      image: lookbook["image"],
      source_parent_id: lookbook["source_parent_id"]
    }
  end
end
