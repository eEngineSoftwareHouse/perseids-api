defmodule Perseids.SessionView do
  def render("session.json", %{session: session}) do
      session_json(session)
  end

  def render("error.json", %{message: message}) do
    %{ errors: [message] }
  end

  defp session_json(session) do
    %{
      session_id: BSON.ObjectId.encode!(session["_id"]),
    }
  end
end
