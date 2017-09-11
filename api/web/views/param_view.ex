defmodule Perseids.ParamView do
  #use Perseids.Web, :view

  def render("index.json", %{product_params: params}) do
    Enum.map(params, &param_json/1)
  end

  def render("param.json", %{param: param}) do
    param_json(param)
  end

  defp param_json(param) do
    %{
      id: BSON.ObjectId.encode!(param["_id"]),
      code: param["code"],
      name: param["name"],
      values: param["values"]
    }
  end
end
