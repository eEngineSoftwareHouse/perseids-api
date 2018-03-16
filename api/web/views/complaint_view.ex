defmodule Perseids.ComplaintView do
  def render("complaint.json", %{complaint: complaint}) do
    %{
      id: BSON.ObjectId.encode!(complaint["_id"]),
      created_at: complaint["created_at"],
      email: complaint["email"],
      order_id: complaint["order_id"],
      comment: complaint["comment"],
      image: complaint["image"]
    }
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
end
