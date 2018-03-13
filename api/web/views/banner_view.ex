defmodule Perseids.BannerView do
  def render("index.json", %{banners: banners}) do
    Enum.map(banners, &banner_json/1)
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

  defp banner_json(banner) do
    %{
      id: BSON.ObjectId.encode!(banner["_id"]),
      url: banner["url"],
      grid: banner["grid"],
      order: banner["order"],
      size: banner["size"],
      alt: banner["alt"],
      image: banner["image"]
    }
  end
end
