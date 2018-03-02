defmodule Perseids.OrderControllerTest do
  use Perseids.ConnCase

  alias Perseids
  alias Perseids.Order

  # @create_attrs %{}
  # @update_attrs %{}
  # @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all index", %{conn: conn} do
      conn = get conn, order_path(conn, :index)
      assert json_response(conn, 200) == []
    end
  end
end
