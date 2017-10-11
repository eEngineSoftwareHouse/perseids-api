defmodule Perseids.ThresholdView do
  def render("index.json", %{thresholds: thresholds}) do
    Enum.map(thresholds, &threshold_json/1)
  end

  def render("threshold.json", %{threshold: threshold}) do
    threshold_json(threshold)
  end

  defp threshold_json(threshold) do
    %{
      id: BSON.ObjectId.encode!(threshold["_id"]),
      value: threshold["value"],
      source_id: threshold["source_id"],
    }
  end
end
