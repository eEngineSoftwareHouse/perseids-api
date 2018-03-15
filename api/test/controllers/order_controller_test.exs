defmodule Perseids.OrderControllerTest do
  use Perseids.ConnCase, async: true
  
  alias Perseids

  @valid_credentials %{"email" => "szymon.ciolkowski@eengine.pl", "password" => "Tajnafraza12"}
  @wholesale_valid_credentials %{"email" => "szymon.ciolkowski+1@eengine.pl", "password" => "Tajnafraza12"}
  
  defp logged_in(conn), do: conn |> Perseids.ConnCase.login(@valid_credentials, "pl_pln")
  defp wholesaler_logged_in(conn), do: conn |> Perseids.ConnCase.login(@wholesale_valid_credentials, "pl_pln")
  defp guest(conn), do: conn |> Perseids.ConnCase.guest("pl_pln")

  setup %{conn: conn} do
    {:ok, conn: conn}
  end

  # ===================================================
  # Orders listing
  # ===================================================
  
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

  # ===================================================
  # Guest user
  # ===================================================

  describe "Guest order - " do
    test "cannot place order without products", %{conn: conn} do
      conn
      |> place_order(valid_order() |> Map.drop(["products"]), :guest)
      |> assert_json_error("products")
    end

    test "cannot place order without email", %{conn: conn} do
      conn
      |> place_order(valid_order() |> Map.drop(["email"]), :guest)
      |> assert_json_error("email")
    end

    test "cannot place order without payment", %{conn: conn} do
      conn
      |> place_order(valid_order() |> Map.drop(["payment"]), :guest)
      |> assert_json_error("payment")
    end

    test "cannot place order without shipping", %{conn: conn} do
      conn
      |> place_order(valid_order() |> Map.drop(["shipping"]), :guest)
      |> assert_json_error("shipping")
    end

    test "cannot place order without address", %{conn: conn} do
      conn
      |> place_order(valid_order() |> Map.drop(["address"]), :guest)
      |> assert_json_error("address")
    end

    test "cannot place order if invoice is chosen but payment address fields are missing", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("invoice", true)
      
      conn
      |> place_order(order_params, :guest)
      |> assert_json_error("address")
    end

    test "can place order if invoice is chosen and payment address fields are send properly", %{conn: conn} do
      address =  %{
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
          "city" => "TestCity",
          "company" => "Test Inc.",
          "country" => "PL",
          "name" => "John",
          "nip" => "1231231212",
          "phone-number" => "123123123",
          "post-code" => "95-070",
          "street" => "TestStreet 1",
          "surname" => "Tester"
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
      }

      order_params = valid_order()
      |> Map.put("invoice", true)
      |> Map.put("address", address)
      
      conn = conn
      |> place_order(order_params, :guest)

      assert json_response(conn, 200)
      assert conn.resp_body =~ "payment_id"
    end

    test "should return redirect link if PayPal payment was chosen", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("payment", "paypal-pre")

      conn = conn
      |> place_order(order_params, :guest)

      assert json_response(conn, 200)
      assert conn.resp_body =~ "redirect_url"
    end

    test "should return redirect link if PayU payment was chosen", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("payment", "payu-pre")

      conn = conn
      |> place_order(order_params, :guest)

      assert json_response(conn, 200)
      assert conn.resp_body =~ "redirect_url"
    end

    test "should fail if paczkomat-PL shipping was chosen but no inpost_code was sent", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("shipping", "paczkomat-PL")

      conn = conn
      |> place_order(order_params, :guest)

      assert json_response(conn, 422)
      assert conn.resp_body =~ "errors"
      assert conn.resp_body =~ "inpost_code"
    end

    test "can place order if paczkomat-PL shipping was chosen and inpost_code was sent", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("shipping", "paczkomat-PL")
      |> Map.put("inpost_code", "PAR01")

      conn = conn
      |> place_order(order_params, :guest)

      assert json_response(conn, 200)
      assert conn.resp_body =~ "payment_id"
    end
  end

  # ===================================================
  # Logged in user
  # ===================================================

  describe "Logged in user order - " do
    test "cannot place order without products", %{conn: conn} do
      conn
      |> place_order(valid_order() |> Map.drop(["products"]), :logged_in)
      |> assert_json_error("products")
    end

    test "cannot place order without email", %{conn: conn} do
      conn
      |> place_order(valid_order() |> Map.drop(["email"]), :logged_in)
      |> assert_json_error("email")
    end

    test "cannot place order without payment", %{conn: conn} do
      conn
      |> place_order(valid_order() |> Map.drop(["payment"]), :logged_in)
      |> assert_json_error("payment")
    end

    test "cannot place order without shipping", %{conn: conn} do
      conn
      |> place_order(valid_order() |> Map.drop(["shipping"]), :logged_in)
      |> assert_json_error("shipping")
    end

    test "cannot place order without address", %{conn: conn} do
      conn
      |> place_order(valid_order() |> Map.drop(["address"]), :logged_in)
      |> assert_json_error("address")
    end

    test "cannot place order if invoice is chosen but payment address fields are missing", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("invoice", true)
      
      conn
      |> place_order(order_params, :logged_in)
      |> assert_json_error("address")
    end

    test "can place order if invoice is chosen and payment address fields are send properly", %{conn: conn} do
      address =  %{
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
          "city" => "TestCity",
          "company" => "Test Inc.",
          "country" => "PL",
          "name" => "John",
          "nip" => "1231231212",
          "phone-number" => "123123123",
          "post-code" => "95-070",
          "street" => "TestStreet 1",
          "surname" => "Tester"
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
      }

      order_params = valid_order()
      |> Map.put("invoice", true)
      |> Map.put("address", address)
      
      conn = conn
      |> place_order(order_params, :logged_in)

      assert json_response(conn, 200)
      assert conn.resp_body =~ "payment_id"
    end

    test "should return redirect link if PayPal payment was chosen", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("payment", "paypal-pre")

      conn = conn
      |> place_order(order_params, :logged_in)

      assert json_response(conn, 200)
      assert conn.resp_body =~ "redirect_url"
    end

    test "should return redirect link if PayU payment was chosen", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("payment", "payu-pre")

      conn = conn
      |> place_order(order_params, :logged_in)

      assert json_response(conn, 200)
      assert conn.resp_body =~ "redirect_url"
    end

    test "should fail if paczkomat-PL shipping was chosen but no inpost_code was sent", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("shipping", "paczkomat-PL")

      conn = conn
      |> place_order(order_params, :logged_in)

      assert json_response(conn, 422)
      assert conn.resp_body =~ "errors"
      assert conn.resp_body =~ "inpost_code"
    end

    test "can place order if paczkomat-PL shipping was chosen and inpost_code was sent", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("shipping", "paczkomat-PL")
      |> Map.put("inpost_code", "PAR01")

      conn = conn
      |> place_order(order_params, :logged_in)

      assert json_response(conn, 200)
      assert conn.resp_body =~ "payment_id"
    end
  end

  # ===================================================
  # Wholesale user
  # ===================================================
  describe "Wholesale user order - " do
    test "should always have automatically added \"banktransfer\" payment and some shipping_code", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("wholesale", true)
      |> Map.put("shipping", "wholesale-PL1")
      |> Map.put("payment", "placeholder")

      conn = conn
      |> place_order(order_params, :wholesaler)

      assert json_response(conn, 200)
      assert conn.resp_body =~ "payment_id"

      order_id = Poison.decode!(conn.resp_body)["payment_id"]
      order = Mongo.find(:mongo, "orders", %{_id: BSON.ObjectId.decode!(order_id)}) |> Enum.to_list |> List.first

      assert Map.has_key?(order, "payment_code")
      assert Map.has_key?(order, "shipping_code")
      assert order["shipping_code"] == "dpd_default"
      assert order["payment_code"] == "banktransfer"
    end
  end

  # Utilities

  defp assert_json_error(conn, fieldname, status \\ 422) do
    assert json_response(conn, status)
    assert conn.resp_body =~ "errors"
    assert conn.resp_body =~ fieldname
  end

  defp place_order(conn, order_params, :logged_in) do
    conn 
    |> logged_in 
    |> place_order(order_params)
  end
  
  defp place_order(conn, order_params, :guest) do
    conn 
    |> guest 
    |> place_order(order_params)
  end

  defp place_order(conn, order_params, :wholesaler) do
    conn 
    |> wholesaler_logged_in 
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
