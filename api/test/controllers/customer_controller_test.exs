defmodule Perseids.CustomerControllerTest do
  use Perseids.ConnCase, async: true
  alias Perseids.CustomerController
  alias Perseids.Plugs.CurrentUser

  @valid_email Time.utc_now |> to_string() |> String.replace(~r/\W/, "-")
  @valid_credentials %{"email" => "test-api@test.pl", "password" => "Tajnafraza12"}
  @valid_params %{customer: %{email: "testowy-#{@valid_email}@testowy.pl", firstname: "Stefan", lastname: "Testowy"}, password: "Tajnafraza12"}

  
  defp logged_in(conn), do: conn |> Perseids.ConnCase.login(@valid_credentials, "pl_pln")
  defp guest(conn), do: conn |> Perseids.ConnCase.guest("pl_pln")
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
    conn = put_req_header(conn, "content-type", "application/json")
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
      assert json_response(conn, 200) # odpowiada 200 przy błędzie a nie powinien 400 ??
      assert conn.resp_body =~ "errors"
      assert conn.resp_body =~ "customer"
    end

    # test "cannot create new account without password", %{conn: conn} do
    #   invalid_params = %{customer: %{email: "testowy-#{@valid_email}1@testowy.pl", firstname: "Stefan", lastname: "Testowy"}}
    #   IO.inspect invalid_params
    #   conn = conn
    #   |> guest
    #   |> CustomerController.create(invalid_params)
    #   assert json_response(conn, 400)
    #   assert conn.resp_body =~ "errors"
    #   assert conn.resp_body =~ "password"
    # end

    test "password reset", %{conn: conn} do
      conn = conn
      |> logged_in
      |> CustomerController.password_reset(%{"email" => @valid_credentials["email"], "website_id" => 1})
      assert conn.resp_body =~ "true"
      assert json_response(conn, 200)
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
