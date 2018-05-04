defmodule Perseids.OrderControllerTest do
  use Perseids.ConnCase, async: true
  
  alias Perseids


  @valid_credentials %{"email" => "szymon.ciolkowski@eengine.pl", "password" => "Tajnafraza12"}
  @wholesale_valid_credentials %{"email" => "szymon.ciolkowski+1@eengine.pl", "password" => "Tajnafraza12"}
  
  defp logged_in(conn), do: conn |> Perseids.ConnCase.login(@valid_credentials, "pl_pln")
  defp wholesaler_logged_in(conn), do: conn |> Perseids.ConnCase.login(@wholesale_valid_credentials, "pl_pln")
  defp guest(conn), do: conn |> Perseids.ConnCase.guest("pl_pln")
  defp assert_json_response(conn, list), do: conn |> Perseids.ConnCase.check_json_response(list, :assert) 
  defp refute_json_response(conn, list), do: conn |> Perseids.ConnCase.check_json_response(list, :refute) 

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

    @tag :magento
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

    test "can use shipping discount code", %{conn: conn} do
    
      order_params = valid_order()
      |> Map.put("discount_code", "TEST_SHIPPING")

      conn = conn
      |> place_order(order_params, :guest)
      assert json_response(conn, 200)
      assert conn.resp_body =~ "\"shipping_price\":0"
    end

    test "can use fixed_11 discount code", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("discount_code", "TEST_FIXED_11")

      conn = conn
      |> place_order(order_params, :guest)
      assert json_response(conn, 200)
      assert conn.resp_body =~ "\"order_total_price\":13.99"
    end

    test "can use fixed_50 discount code and it should return 0", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("discount_code", "TEST_FIXED_50")

      conn = conn
      |> place_order(order_params, :guest)
      assert json_response(conn, 200)
      assert conn.resp_body =~ "\"order_total_price\":9.99"
    end

    test "can use percent discount code", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("discount_code", "TEST_PERCENT")

      conn = conn
      |> place_order(order_params, :guest)
      assert json_response(conn, 200)
      assert conn.resp_body =~ "\"order_total_price\":23.490000000000002"
    end

    test "can't obtain free low/regular socks if total price < 99", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("products", valid_free_products(1))

      conn = conn
      |> place_order(order_params, :guest)

      valid_response = [
        "\"name\":\"BEETROOT-39-42\",\"id\":\"51\",\"free\":null,\"count\":1}"
      ]
      invalid_response = [
        "\"name\":\"PIGGY TALES LOW-35-38\",\"id\":\"155\",\"free\":\"free_low\",\"count\":1",
        "\"name\":\"EL LEOPARDO-43-46\",\"id\":\"458\",\"free\":\"free_regular\",\"count\":1"
      ]
      assert json_response(conn, 200)      
      assert_json_response(conn, valid_response)
      refute_json_response(conn, invalid_response)
    end

    test "can obtain free low socks if total price < 199 and total price >= 149", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("products", valid_free_products(7))

      conn = conn
      |> place_order(order_params, :guest)

      valid_response = [
        "\"name\":\"BEETROOT-39-42\",\"id\":\"51\",\"free\":null,\"count\":7}",
        "\"name\":\"PIGGY TALES LOW-35-38\",\"id\":\"155\",\"free\":\"free_low\",\"count\":1"
      ]
      invalid_response = [
        "\"name\":\"EL LEOPARDO-43-46\",\"id\":\"458\",\"free\":\"free_regular\",\"count\":1",
      ]
      assert json_response(conn, 200)
      assert_json_response(conn, valid_response)
      refute_json_response(conn, invalid_response)
    end

    test "can obtain free low/regular socks if total price >= 199", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("products", valid_free_products(10))

      conn = conn
      |> place_order(order_params, :guest)

      valid_response = [
        "\"name\":\"BEETROOT-39-42\",\"id\":\"51\",\"free\":null,\"count\":10}",
        "\"name\":\"PIGGY TALES LOW-35-38\",\"id\":\"155\",\"free\":\"free_low\",\"count\":1",
        "\"name\":\"EL LEOPARDO-43-46\",\"id\":\"458\",\"free\":\"free_regular\",\"count\":1"
      ]
      assert json_response(conn, 200)
      assert_json_response(conn, valid_response)
    end
    test "can obtain only 1 pair of low socks when credentials are met", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("products", invalid_free_products(7))

      conn = conn
      |> place_order(order_params, :guest)

      valid_response = [
        "\"name\":\"BEETROOT-39-42\",\"id\":\"51\",\"free\":null,\"count\":7}",
        "\"name\":\"PIGGY TALES LOW-35-38\",\"id\":\"155\",\"free\":\"free_low\",\"count\":1"
      ]
      invalid_response = [
        "\"name\":\"EL LEOPARDO-43-46\",\"id\":\"458\",\"free\":\"free_regular\",\"count\":1",
      ]
      assert json_response(conn, 200)
      assert_json_response(conn, valid_response)
      refute_json_response(conn, invalid_response)

      response_json = conn.resp_body |> Poison.decode!

      assert response_json["products"] |> check_field_count("name", "PIGGY TALES LOW-35-38") == 1
    end

    test "can obtain only 1 pair of low socks and 1 pair of regular socks when credentials are met", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("products", invalid_free_products(10))

      conn = conn
      |> place_order(order_params, :guest)

      valid_response = [
        "\"name\":\"BEETROOT-39-42\",\"id\":\"51\",\"free\":null,\"count\":10}",
        "\"name\":\"PIGGY TALES LOW-35-38\",\"id\":\"155\",\"free\":\"free_low\",\"count\":1",
        "\"name\":\"EL LEOPARDO-43-46\",\"id\":\"458\",\"free\":\"free_regular\",\"count\":1"
      ]

      assert json_response(conn, 200)
      assert_json_response(conn, valid_response)

      response_json = conn.resp_body |> Poison.decode!

      assert response_json["products"] |> check_field_count("name", "PIGGY TALES LOW-35-38") == 1
      assert response_json["products"] |> check_field_count("name", "EL LEOPARDO-43-46") == 1
    end

    test "should return list of countries", %{conn: conn} do
      conn = conn 
      |> guest 
      |> Perseids.OrderController.delivery_options(%{})
      |> assert_json_response(["PL", "Polska"])

      assert json_response(conn, 200)
    end
  end

  # ===================================================
  # Logged in user
  # ===================================================

  describe "Logged in user order - " do
    @describetag :magento  
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
      |> Phoenix.Controller.put_view(Perseids.OrderView)
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

    test "can use shipping discount code", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("discount_code", "TEST_SHIPPING")

      conn = conn
      |> place_order(order_params, :logged_in)
      assert json_response(conn, 200)
      assert conn.resp_body =~ "\"shipping_price\":0"
    end
    
    test "can use fixed_11 discount code", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("discount_code", "TEST_FIXED_11")

      conn = conn
      |> place_order(order_params, :logged_in)
      assert json_response(conn, 200)
      assert conn.resp_body =~ "\"order_total_price\":13.99"
    end

    test "can use fixed_50 discount code and it should return 0", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("discount_code", "TEST_FIXED_50")

      conn = conn
      |> place_order(order_params, :logged_in)
      assert json_response(conn, 200)
      assert conn.resp_body =~ "\"order_total_price\":9.99"
    end

    test "can use percent discount code", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("discount_code", "TEST_PERCENT")

      conn = conn
      |> place_order(order_params, :logged_in)
      assert json_response(conn, 200)
      assert conn.resp_body =~ "\"order_total_price\":23.490000000000002"
    end

    test "can't obtain free low/regular socks if total price < 99", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("products", valid_free_products(1))

      conn = conn
      |> place_order(order_params, :logged_in)

      valid_response = [
        "\"name\":\"BEETROOT-39-42\",\"id\":\"51\",\"free\":null,\"count\":1}"
      ]
      invalid_response = [
        "\"name\":\"PIGGY TALES LOW-35-38\",\"id\":\"155\",\"free\":\"free_low\",\"count\":1",
        "\"name\":\"EL LEOPARDO-43-46\",\"id\":\"458\",\"free\":\"free_regular\",\"count\":1"
      ]
      assert json_response(conn, 200)      
      assert_json_response(conn, valid_response)
      refute_json_response(conn, invalid_response)
    end

    test "can obtain free low socks if total price < 199 and total price >= 149", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("products", valid_free_products(7))

      conn = conn
      |> place_order(order_params, :logged_in)

      valid_response = [
        "\"name\":\"BEETROOT-39-42\",\"id\":\"51\",\"free\":null,\"count\":7}",
        "\"name\":\"PIGGY TALES LOW-35-38\",\"id\":\"155\",\"free\":\"free_low\",\"count\":1"
      ]
      invalid_response = [
        "\"name\":\"EL LEOPARDO-43-46\",\"id\":\"458\",\"free\":\"free_regular\",\"count\":1",
      ]
      assert json_response(conn, 200)
      assert_json_response(conn, valid_response)
      refute_json_response(conn, invalid_response)
    end

    test "can obtain free low/regular socks if total price >= 199", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("products", valid_free_products(10))

      conn = conn
      |> place_order(order_params, :logged_in)

      valid_response = [
        "\"name\":\"BEETROOT-39-42\",\"id\":\"51\",\"free\":null,\"count\":10}",
        "\"name\":\"PIGGY TALES LOW-35-38\",\"id\":\"155\",\"free\":\"free_low\",\"count\":1",
        "\"name\":\"EL LEOPARDO-43-46\",\"id\":\"458\",\"free\":\"free_regular\",\"count\":1"
      ]
      assert json_response(conn, 200)
      assert_json_response(conn, valid_response)
    end

    test "can obtain only 1 pair of low socks when credentials are met", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("products", invalid_free_products(7))

      conn = conn
      |> place_order(order_params, :logged_in)

      valid_response = [
        "\"name\":\"BEETROOT-39-42\",\"id\":\"51\",\"free\":null,\"count\":7}",
        "\"name\":\"PIGGY TALES LOW-35-38\",\"id\":\"155\",\"free\":\"free_low\",\"count\":1"
      ]
      invalid_response = [
        "\"name\":\"EL LEOPARDO-43-46\",\"id\":\"458\",\"free\":\"free_regular\",\"count\":1",
      ]
      assert json_response(conn, 200)
      assert_json_response(conn, valid_response)
      refute_json_response(conn, invalid_response)

      response_json = conn.resp_body |> Poison.decode!

      assert response_json["products"] |> check_field_count("name", "PIGGY TALES LOW-35-38") == 1
    end

    test "obtain only 1 pair of low socks and 1 pair of regular socks when credentials are met", %{conn: conn} do
      order_params = valid_order()
      |> Map.put("products", invalid_free_products(10))

      conn = conn
      |> place_order(order_params, :logged_in)

      valid_response = [
        "\"name\":\"BEETROOT-39-42\",\"id\":\"51\",\"free\":null,\"count\":10}",
        "\"name\":\"PIGGY TALES LOW-35-38\",\"id\":\"155\",\"free\":\"free_low\",\"count\":1",
        "\"name\":\"EL LEOPARDO-43-46\",\"id\":\"458\",\"free\":\"free_regular\",\"count\":1"
      ]

      assert json_response(conn, 200)
      assert_json_response(conn, valid_response)

      response_json = conn.resp_body |> Poison.decode!
      
      assert response_json["products"] |> check_field_count("name", "PIGGY TALES LOW-35-38") == 1
      assert response_json["products"] |> check_field_count("name", "EL LEOPARDO-43-46") == 1
    end

    test "should return list of countries", %{conn: conn} do
      conn = conn 
      |> logged_in 
      |> Perseids.OrderController.delivery_options(%{})
      |> assert_json_response(["PL", "Polska"])

      assert json_response(conn, 200)
    end
  end

  # ===================================================
  # Wholesale user
  # ===================================================

  describe "Wholesale user order - " do
    @describetag :magento  
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

    test "should return list of countries", %{conn: conn} do
      conn = conn 
      |> wholesaler_logged_in  
      |> Perseids.OrderController.wholesale_delivery_options(%{})
      |> assert_json_response(["PL", "Polska"])

      assert json_response(conn, 200)
    end
  end

  # Utilities

  defp check_field_count(list, field, compare) do
    list
      |> Enum.filter(fn(elem) -> elem[field] == compare end) 
      |> Enum.count
  end

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
          %{"count" => 1, "id" => "183", "name" => "THE LEMONS LOW-35-38", "sku" => "L10-35-38", "variant_id" => "180"}
        ],
      "shipping" => "kurier-PL"
    }
  end
  
  defp valid_free_products(count) do
    [
      %{
        "id" => "155",
        "variant_id" => "152",
        "count" => 1,
        "sku" => "F-L13-43-46",
        "name" => "PIGGY TALES LOW-35-38"
      },
      %{
        "id" => "458",
        "variant_id" => "457",
        "count" => 1,
        "sku" => "R67-43-46",
        "name" => "EL LEOPARDO-43-46"
      },
      %{
        "id" => "51",
        "variant_id" => "49",
        "count" => count,
        "sku" => "R2-39-42",
        "name" => "BEETROOT-39-42"
      }
    ]
  end

  defp invalid_free_products(count) do 
    [
        %{
          "id" => "155",
          "variant_id" => "152",
          "count" => 100,
          "sku" => "F-L13-43-46",
          "name" => "PIGGY TALES LOW-35-38"
        },
        %{
          "id" => "155",
          "variant_id" => "152",
          "count" => 100,
          "sku" => "F-L13-43-46",
          "name" => "PIGGY TALES LOW-35-38"
        },
        %{
          "id" => "155",
          "variant_id" => "152",
          "count" => 100,
          "sku" => "F-L13-43-46",
          "name" => "PIGGY TALES LOW-35-38"
        },
        %{
          "id" => "458",
          "variant_id" => "457",
          "count" => 5,
          "sku" => "R67-43-46",
          "name" => "EL LEOPARDO-43-46"
        },
        %{
          "id" => "458",
          "variant_id" => "457",
          "count" => 5,
          "sku" => "R67-43-46",
          "name" => "EL LEOPARDO-43-46"
        },
        %{
          "id" => "458",
          "variant_id" => "457",
          "count" => 10,
          "sku" => "R67-43-46",
          "name" => "EL LEOPARDO-43-46"
        },
        %{
          "id" => "155",
          "variant_id" => "152",
          "count" => 100,
          "sku" => "F-L13-43-46",
          "name" => "PIGGY TALES LOW-35-38"
        },
        %{
          "id" => "51",
          "variant_id" => "49",
          "count" => count,
          "sku" => "R2-39-42",
          "name" => "BEETROOT-39-42"
        }
    ]
  end
end
