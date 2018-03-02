defmodule Perseids.ErrorView do
  use Perseids.Web, :view

  def render(:"404", _) do
    # When encoded, the changeset returns its errors
    # as a JSON object. So we just pass it forward.
    %{errors: ["not found"]}
  end
end
