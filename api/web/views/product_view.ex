defmodule Perseids.ProductView do
  #use Perseids.Web, :view

  def render("index.json", %{products: products, count: count, params: params}) do
    %{
      "count" => count,
      "products" => Enum.map(products, &product_json/1),
      "params" => params
    }
  end

  def render("product.json", %{product: product}) do
    product_json(product)
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

  defp product_json(product) do
    product
    |> Map.drop(["_id"])
    |> Helpers.atomize_keys
  end
end
