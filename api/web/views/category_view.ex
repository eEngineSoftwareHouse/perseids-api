defmodule Perseids.CategoryView do
  def render("index.json", %{categories: categories}) do
    Enum.map(categories, &category_json/1)
  end

  def render("category.json", %{category: category}) do
    category_json(category)
  end

  defp category_json(category) do
    %{
      id: BSON.ObjectId.encode!(category["_id"]),
      name: category["name"],
      slug: category["name"] |> String.downcase |> String.normalize(:nfd) |> String.replace(~r/[^A-z\s]/u, "") |> String.replace(~r/\s/, "-"),
      source_id: category["source_id"],
      source_parent_id: category["source_parent_id"],
      image: category["image"],
      description: category["description"]
    }
  end
end
