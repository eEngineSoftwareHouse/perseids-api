defmodule Perseids.ThresholdController do
  use Perseids.Web, :controller
  alias Perseids.Threshold

  def index(conn, params) do
    thresholds = Helpers.to_keyword_list(params)
    |> ORMongo.set_language(conn)
    |> Threshold.find

    render conn, "index.json", thresholds: thresholds
  end

  def show(%{assigns: %{lang: lang}} = conn, %{"source_id" => source_id}) do
    render conn, "threshold.json", threshold: Threshold.find_one(source_id: source_id, lang: lang)
  end
end
