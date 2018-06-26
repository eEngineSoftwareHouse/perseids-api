defmodule Perseids.NavbarControllerTest do
  use Perseids.ConnCase, async: true
  
  alias Perseids

  @admin_valid_credentials %{"email" => "admin@example.com", "password" => "Tajnafraza12"}
  @valid_credentials %{"email" => "test-api@niepodam.pl", "password" => "Tajnafraza12"}
  @wholesale_valid_credentials %{"email" => "wholesaler@example.com", "password" => "Tajnafraza12"}

  defp guest(conn), do: conn |> Perseids.ConnCase.guest("pl_pln")
  defp logged_in(conn), do: conn |> Perseids.ConnCase.login(@valid_credentials, "pl_pln")
  defp wholesaler(conn), do: conn |> Perseids.ConnCase.login(@wholesale_valid_credentials, "pl_pln")
  defp admin(conn), do: conn |> Perseids.ConnCase.login(@admin_valid_credentials, "pl_pln")
  
  setup %{conn: conn} do
    {:ok, conn: conn}
  end


  describe "Guest - " do
    test "can fetch navbars", %{conn: conn} do
      conn = 
        conn 
        |> guest
        |> get(navbar_path(conn, :index))

      assert json_response(conn, 200)
      assert conn.resp_body |> Poison.decode! |> Enum.count == 3
    end  

    test "can't update page", %{conn: conn} do
      conn = conn
      |> guest
      |> post(navbar_path(conn, :update, edit_navbar_params()))

      assert json_response(conn, 401)
    end
  end

  describe "Logged in - " do
    test "can fetch navbars", %{conn: conn} do
      conn = 
        conn 
        |> logged_in
        |> get(navbar_path(conn, :index))

      assert json_response(conn, 200)
      assert conn.resp_body |> Poison.decode! |> Enum.count == 3
    end  
  
    test "can't update page", %{conn: conn} do
      conn = conn
      |> logged_in
      |> post(navbar_path(conn, :update, edit_navbar_params()))

      assert json_response(conn, 401)
    end
  end

  describe "Wholesaler - " do
    test "can fetch navbars", %{conn: conn} do
      conn = 
        conn 
        |> wholesaler
        |> get(navbar_path(conn, :index))

      assert json_response(conn, 200)
      assert conn.resp_body |> Poison.decode! |> Enum.count == 3
    end  

    test "can't update page", %{conn: conn} do
      conn = conn
      |> wholesaler
      |> post(navbar_path(conn, :update, edit_navbar_params()))

      assert json_response(conn, 401)
    end
  end

  describe "Admin -" do
    test "can fetch navbars", %{conn: conn} do
      conn = 
        conn 
        |> admin
        |> get(navbar_path(conn, :index))

      assert json_response(conn, 200)
      assert conn.resp_body |> Poison.decode! |> Enum.count == 3
    end  
  
    test "can update page", %{conn: conn} do
      conn = conn
      |> admin
      |> post(navbar_path(conn, :update, edit_navbar_params()))

      assert json_response(conn, 200)
    end
  end

  defp edit_navbar_params do
    %{
      "slug" => "Po edicie",
      "title" => "Edytowane bylo",
      "order" => 1
    }
  end
end
