defmodule Perseids.CustomerControllerTest do
  use Perseids.ConnCase, async: true
  alias Perseids.CustomerController
  alias Perseids.Plugs.CurrentUser

  @moduletag :magento

  @valid_email Time.utc_now |> to_string() |> String.replace(~r/\W/, "-")
  @valid_credentials %{"email" => "test-api@niepodam.pl", "password" => "Tajnafraza12"}
  @valid_params %{customer: %{email: "testowy-#{@valid_email}@testowy.pl", firstname: "Stefan", lastname: "Testowy"}, password: "Tajnafraza12"}

  
  defp logged_in(conn), do: conn |> Perseids.ConnCase.login(@valid_credentials, "pl_pln")
  defp guest(conn), do: conn |> Perseids.ConnCase.guest("pl_pln")
  defp reset_password(conn, params) do
    conn
    |> guest
    |> CustomerController.password_reset(params)
  end
  defp valid_adresses do
    [
      %{
        "city" => "Testowo",
        "company" => "Testowo-#{Time.utc_now}",
        "country_id" => "PN",
        "customer_id" => 30764,
        "firstname" => "NEw",
        "id" => 12871,
        "lastname" => "New",
        "postcode" => "90-123",
        "region" =>  %{
                        "region_id" => 0, 
                        "region_code" => NULL, 
                        "region" => NULL
                      },
        "street" => ["Test 1"],
        "telephone" => "123123123",
        "vat_id" => "1321121212"
      }
    ]
  end

  setup %{conn: conn} do 
    conn 
    |> put_req_header("content-type", "application/json")
    {:ok, conn: conn}
  end


  describe "Customer -" do
    test "create new account", %{conn: conn} do
      conn = conn
      |> guest
      |> CustomerController.create(@valid_params)
      assert json_response(conn, 200)
      assert conn.resp_body =~ "updated_at"
      assert conn.resp_body =~ "created_at"
      assert conn.resp_body =~ "created_in"
      assert conn.resp_body =~ @valid_params[:customer][:email]
      assert conn.resp_body =~ @valid_params[:customer][:firstname]
      assert conn.resp_body =~ @valid_params[:customer][:lastname]
    end

    test "cannot create new account without customer data", %{conn: conn} do
      invalid_params = @valid_params |> Map.drop([:customer])
      conn = conn
      |> guest
      |> CustomerController.create(invalid_params)
      assert json_response(conn, 422)
      assert conn.resp_body =~ "errors"
      assert conn.resp_body =~ "customer"
    end

    @tag :pending
    test "cannot create new account without password", %{conn: conn} do
      invalid_params = %{customer: %{email: "testowy-#{@valid_email}1@testowy.pl", firstname: "Stefan", lastname: "Testowy"}}
      conn = conn
      |> guest
      |> CustomerController.create(invalid_params)
      assert json_response(conn, 422)
      assert conn.resp_body =~ "errors"
      assert conn.resp_body =~ "hasła"
    end

    test "password reset -- can send reset email", %{conn: conn} do
      conn = conn
      |> reset_password(%{"email" => @valid_credentials["email"], "website_id" => 1})
      assert conn.resp_body =~ "true"
      assert json_response(conn, 200)
    end

    test "password reset -- cannot reset without token", %{conn: conn} do
      conn = conn
      |> reset_password(%{"password" => "Tajnafraza10", "password_confirmation" => "Tajnafraza10", "token" => "token", "email" => @valid_credentials["email"]})
      assert conn.resp_body =~ "errors"
      assert conn.resp_body =~ "token"
      assert json_response(conn, 422)
    end

    test "password reset -- cannot reset without email", %{conn: conn} do
      conn = conn
      |> reset_password(%{"password" => "Tajnafraza10", "password_confirmation" => "Tajnafraza10", "token" => "token", "email" => ""})
      assert conn.resp_body =~ "errors"
      assert conn.resp_body =~ "email"
      assert json_response(conn, 422)
    end

    test "password reset -- cannot reset with diffrence password", %{conn: conn} do
      conn = conn
      |> reset_password(%{"password" => "Another", "password_confirmation" => "Password", "token" => "token", "email" => @valid_credentials["email"]})
      assert conn.resp_body =~ "errors"
      assert conn.resp_body =~ "Wpisane hasła różnią się od siebie"
      assert json_response(conn, 422)

    end

    test "can update account", %{conn: conn} do
      params = %{"customer" => %{"website_id" => 1, "lastname" => "Testowy-z-dn#{Time.utc_now}", "firstname" => "Stefan", "addresses" => valid_adresses()}}
      conn = conn
      |> logged_in
      |> CurrentUser.call("Nothing important")
      |> CustomerController.update(params)
      assert conn.resp_body =~ "Stefan"
      assert conn.resp_body =~ "Testowy-z-dn"
      assert json_response(conn, 200) 
    end  

  end
end
