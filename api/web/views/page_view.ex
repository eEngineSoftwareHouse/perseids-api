defmodule Perseids.PageView do
  def render("index.json", %{pages: pages}) do
    Enum.map(pages, &page_json/1)
  end

  def render("page.json", %{page: nil}) do
    %{}
  end

  def render("page.json", %{page: page}) do
    page_json(page)
  end

  defp page_json(page) do
    %{
      slug: page["slug"],
      content: page["content"]
    }
  end
end
