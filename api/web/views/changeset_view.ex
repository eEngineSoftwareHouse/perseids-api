defmodule Perseids.ChangesetView do
  use Perseids.Web, :view

  @doc """
  Traverses and translates changeset errors.

  See `Ecto.Changeset.traverse_errors/2` and
  `Perseids.ErrorHelpers.translate_error/1` for more details.
  """
  def render("error.json", %{changeset: changeset}) do
    %{ errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/2) }
  end

  defp translate_error(msg, opts) do
    Enum.reduce(opts, msg, fn({key, value}, acc) -> String.replace(acc, "%{#{key}}", to_string(value)) end)
  end
end
