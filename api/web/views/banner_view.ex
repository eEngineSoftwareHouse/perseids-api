defmodule Perseids.BannerView do
  def render("index.json", %{banners: banners}) do
    Enum.map(banners, &banner_json/1)
  end

  defp banner_json(banner) do
    %{
      id: BSON.ObjectId.encode!(banner["_id"]),
      url: banner["url"],
      grid: banner["grid"],
      order: banner["order"],
      alt: banner["alt"],
      image_url: banner["image_url"]
    }
  end
end
