defmodule Perseids.NavbarView do
  def render("index.json", %{navbars: navbars}) do
    navbars |> Enum.map(&navbar_json/1)
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

  defp navbar_json(navbar) do
    %{
      slug: navbar["slug"],
      title: navbar["title"],
      order: navbar["order"]
    }
  end
end
