defmodule Perseids.ParamController do
  use Perseids.Web, :controller
  alias Perseids.Param

  def index(conn, _params) do
    product_params = Param.all

    render conn, "index.json", product_params: product_params
  end

  def show(conn, %{"code" => code}) do
    param = Param.find(%{"code" => code})
    |> Enum.to_list
    |> List.first

    render conn, "param.json", param: param
  end
end
