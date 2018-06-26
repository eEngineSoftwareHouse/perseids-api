defmodule Perseids.PageView do
  def render("index.json", %{pages: pages}) do
    pages |> Enum.map(&page_json/1)
  end

  def render("page.json", %{page: nil}) do
    %{}
  end

  def render("page.json", %{page: page}) do
    page |> page_json
  end

  def render("errors.json", %{changeset: changeset}) do
    %{
      errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)
    }
  end

  defp page_json(page) do
    %{
      id: BSON.ObjectId.encode!(page["_id"]),
      slug: page["slug"],
      content: page["content"],
      title: page["title"],
      seo_title: page["seo_title"],
      seo_description: page["seo_description"],
      position: page["position"],
      active: page["active"]
    }
  end
end
