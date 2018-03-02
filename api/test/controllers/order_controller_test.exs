defmodule Perseids.OrderControllerTest do
  use Perseids.ConnCase, async: true

  import Perseids.Gettext

  alias Perseids
  alias Perseids.Order

  @valid_credentials %{"email" => "szymon.ciolkowski@eengine.pl", "password" => "Tajnafraza12"}
  
  defp logged_in(conn), do: conn |> Perseids.ConnCase.login(@valid_credentials, "pl_pln")
  defp guest(conn), do: conn |> Perseids.ConnCase.guest("pl_pln")

  setup %{conn: conn} do
    {:ok, conn: conn}
  end
  
  describe "Orders listing" do
    test "guest user cannot display orders list", %{conn: conn} do
      conn = conn 
      |> guest
      |> get(order_path(conn, :index))
      assert json_response(conn, 401) == %{"errors" => [gettext "You do not have sufficient permissions."]}
    end

    test "logged in user can display his orders", %{conn: conn} do
      conn = conn 
      |> logged_in
      |> get(order_path(conn, :index))
      assert json_response(conn, 200) == %{"count" => 0, "orders" => []}
    end
  end
  
end
