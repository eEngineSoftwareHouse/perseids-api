defmodule Perseids.OrderControllerTest do
  use Perseids.ConnCase
  
  alias Perseids

  @valid_credentials %{"email" => "szymon.ciolkowski@eengine.pl", "password" => "Tajnafraza12"}
  
  defp logged_in(conn), do: conn |> Perseids.ConnCase.login(@valid_credentials, "pl_pln")
  defp guest(conn), do: conn |> Perseids.ConnCase.guest("pl_pln")

  setup %{conn: conn} do
    {:ok, conn: conn}
  end
  
  describe "Orders listing - " do
    test "guest user cannot display orders list", %{conn: conn} do
      conn = conn 
      |> guest
      |> get(order_path(conn, :index))

      assert json_response(conn, 401)
    end

    test "logged in user can display his orders", %{conn: conn} do
      conn = conn 
      |> logged_in
      |> get(order_path(conn, :index))

      assert json_response(conn, 200)
    end
  end

  describe "Guest Order - " do
    test "cannot place order without products", %{conn: conn} do
      order_params = valid_order()
      |> Map.drop(["products"])

      conn = conn |> place_order(order_params, :guest)

      assert json_response(conn, 400)
      assert conn.resp_body =~ "errors"
      assert conn.resp_body =~ "products"
    end

    test "cannot place order without email", %{conn: conn} do
      order_params = valid_order()
      |> Map.drop(["email"])

      conn = conn |> place_order(order_params, :guest)

      assert json_response(conn, 400)
      assert conn.resp_body =~ "errors"
      assert conn.resp_body =~ "email"
    end

    test "cannot place order without payment", %{conn: conn} do
      order_params = valid_order()
      |> Map.drop(["payment"])

      conn = conn |> place_order(order_params, :guest)

      assert json_response(conn, 400)
      assert conn.resp_body =~ "errors"
      assert conn.resp_body =~ "payment"
    end

    test "cannot place order without shipping", %{conn: conn} do
      order_params = valid_order()
      |> Map.drop(["shipping"])

      conn = conn |> place_order(order_params, :guest)

      assert json_response(conn, 400)
      assert conn.resp_body =~ "errors"
      assert conn.resp_body =~ "shipping"
    end

    test "cannot place order without address", %{conn: conn} do
      order_params = valid_order()
      |> Map.drop(["address"])

      conn = conn |> place_order(order_params, :guest)

      assert json_response(conn, 400)
      assert conn.resp_body =~ "errors"
      assert conn.resp_body =~ "address"
    end
  end


  # Utilities

  defp place_order(conn, order_params, :logged_in) do
    conn 
    |> guest 
    |> place_order(order_params)
  end
  
  defp place_order(conn, order_params, :guest) do
    conn 
    |> guest 
    |> place_order(order_params)
  end
  
  defp place_order(conn, order_params, _other), do: place_order(conn, order_params, :guest)

  defp place_order(conn, order_params) do
    conn
    |> put_req_header("content-type", "application/json")
    |> Phoenix.Controller.put_view(Perseids.OrderView)
    |> Perseids.OrderController.create(order_params)
  end
  
  defp valid_order do
    %{
      "accept_rules" => true,
      "address" => %{
        "customer" => %{
          "city" => "TestCity",
          "country" => "PL",
          "name" => "John",
          "phone-number" => "123123123",
          "post-code" => "95-070",
          "street" => "TestStreet 1",
          "surname" => "Tester"
          },
      "payment" => %{
        "city" => "",
        "company" => "",
        "country" => "PL",
        "name" => "",
        "nip" => "",
        "phone-number" => "",
        "post-code" => "",
        "street" => "",
        "surname" => ""
        },
      "shipping" => %{
        "city" => "TestCity",
        "country" => "PL",
        "name" => "John",
        "phone-number" => "123123123",
        "post-code" => "95-070",
        "street" => "TestStreet 1",
        "surname" => "Tester"
        }
      }, 
      "comment" => "", 
      "discount_code" => "",
      "email" => "customer.email@example.com",
      "invoice" => false,
      "other_shipping_address" => false,
      "payment" => "banktransfer-pre",
      "products" => [
          %{"count" => 1, "id" => "455", "name" => "EL LEOPARDO-35-38", "sku" => "R67-35-38", "variant_id" => "455"}
        ],
      "shipping" => "kurier-PL"
    }
  end
  
end
