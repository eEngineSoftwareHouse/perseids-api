defmodule Perseids.PageControllerTest do
  use Perseids.ConnCase, async: true
  
  alias Perseids

  @admin_valid_credentials %{"email" => "szymon.ciolkowski+admin@eengine.pl", "password" => "Tajnafraza12"}
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
    test "can fetch pages", %{conn: conn} do
      conn = 
        conn 
        |> guest
        |> get(page_path(conn, :index))

      assert json_response(conn, 200)
    end  
  
    test "can show single page", %{conn: conn} do
      conn = 
        conn 
        |> guest
        |> get(page_path(conn, :show, "test-page"))

      assert json_response(conn, 200)  
    end  
  
    test "return 404 if single page is not found", %{conn: conn} do
      conn = 
        conn 
        |> guest
        |> get(page_path(conn, :show, "not-found-test-page"))

      assert json_response(conn, 404)
    end  

    test "can't create new page", %{conn: conn} do
      conn = conn
        |> guest
        |> post(page_path(conn, :create, page_params()))

      assert json_response(conn, 401)
    end

    test "can't destroy page", %{conn: conn} do
      id = find_product_id("test-page")

      conn = conn
      |> guest
      |> post(page_path(conn, :destroy, %{"id" => id}))

      assert json_response(conn, 401)
    end

    test "can't update page", %{conn: conn} do
      id = find_product_id("test-page")

      conn = conn
      |> guest
      |> post(page_path(conn, :update, edit_page_params() |> Map.put_new("id", id)))

      assert json_response(conn, 401)
    end
  end

  describe "Logged in - " do
    test "can fetch pages", %{conn: conn} do
      conn = 
        conn 
        |> logged_in
        |> get(page_path(conn, :index))

      assert json_response(conn, 200)
    end  
  
    test "can show single page", %{conn: conn} do
      conn = 
        conn 
        |> logged_in
        |> get(page_path(conn, :show, "test-page"))

      assert json_response(conn, 200)  
    end  
  
    test "return 404 if single page is not found", %{conn: conn} do
      conn = 
        conn 
        |> logged_in
        |> get(page_path(conn, :show, "not-found-test-page"))

      assert json_response(conn, 404)
    end  

    test "can't create new page", %{conn: conn} do
      conn = conn
        |> logged_in
        |> post(page_path(conn, :create, page_params()))

      assert json_response(conn, 401)
    end

    test "can't destroy page", %{conn: conn} do
      id = find_product_id("test-page")

      conn = conn
      |> logged_in
      |> post(page_path(conn, :destroy, %{"id" => id}))

      assert json_response(conn, 401)
    end

    test "can't update page", %{conn: conn} do
      id = find_product_id("test-page")

      conn = conn
      |> logged_in
      |> post(page_path(conn, :update, edit_page_params() |> Map.put_new("id", id)))

      assert json_response(conn, 401)
    end
  end

  describe "Wholesaler - " do
    test "can fetch pages", %{conn: conn} do
      conn = 
        conn 
        |> wholesaler
        |> get(page_path(conn, :index))

      assert json_response(conn, 200)
    end  
  
    test "can show single page", %{conn: conn} do
      conn = 
        conn 
        |> wholesaler
        |> get(page_path(conn, :show, "test-page"))

      assert json_response(conn, 200)  
    end  
  
    test "return 404 if single page is not found", %{conn: conn} do
      conn = 
        conn 
        |> wholesaler
        |> get(page_path(conn, :show, "not-found-test-page"))

      assert json_response(conn, 404)
    end  

    test "can't create new page", %{conn: conn} do
      conn = conn
        |> wholesaler
        |> post(page_path(conn, :create, page_params()))

      assert json_response(conn, 401)
    end

    test "can't destroy page", %{conn: conn} do
      id = find_product_id("test-page")

      conn = conn
      |> wholesaler
      |> post(page_path(conn, :destroy, %{"id" => id}))

      assert json_response(conn, 401)
    end

    test "can't update page", %{conn: conn} do
      id = find_product_id("test-page")

      conn = conn
      |> wholesaler
      |> post(page_path(conn, :update, edit_page_params() |> Map.put_new("id", id)))

      assert json_response(conn, 401)
    end
  end

  describe "Admin -" do
    test "can fetch pages", %{conn: conn} do
      conn = 
        conn 
        |> admin
        |> get(page_path(conn, :index))

      assert json_response(conn, 200)
    end  
  
    test "can show single page", %{conn: conn} do
      conn = 
        conn 
        |> admin
        |> get(page_path(conn, :show, "test-page"))

      assert json_response(conn, 200)  
    end  
  
    test "return 404 if single page is not found", %{conn: conn} do
      conn = 
        conn 
        |> admin
        |> get(page_path(conn, :show, "not-found-test-page"))

      assert json_response(conn, 404)
    end 

    test "can create new page", %{conn: conn} do
      conn = conn
      |> admin
      |> post(page_path(conn, :create, page_params()))

    assert json_response(conn, 200)
    end

    test "can destroy page", %{conn: conn} do
      id = find_product_id("test-page_2")
      conn = conn
      |> admin
      |> post(page_path(conn, :destroy, %{"id" => id}))

      assert json_response(conn, 200)
    end

    test "can update page", %{conn: conn} do
      id = find_product_id("test-page_update")
      conn = conn
      |> admin
      |> post(page_path(conn, :update, edit_page_params() |> Map.put_new("id", id)))

      assert json_response(conn, 200)
    end
  end

  defp page_params() do
    %{
      "active" => true,
      "content" => "lolopolo",
      "position" => "footer",
      "seo_description" => "lolo",
      "seo_title" => "polo",
      "slug" => "maximum-effort",
      "title" => "Effort!"
    }
  end

  defp duplicate_page_params do
    %{
      "active" => true,
      "content" => "<div> test </div>",
      "position" => "navbar",
      "seo_description" => "test",
      "seo_title" => "test",
      "slug" => "test-page",
      "title" => "Strona Testowa"
    }
  end

  defp edit_page_params do
    %{
      "active" => true,
      "content" => "<div> test </div>",
      "position" => "navbar",
      "seo_description" => "test",
      "seo_title" => "test",
      "slug" => "test-page-222222-UPDATE",
      "title" => "Strona Testowa-222222-UPDATE"
    }
  end

  defp find_product_id(slug), do: Perseids.Page.find_one(slug: slug, lang: "pl_pln")["_id"] |> BSON.ObjectId.encode!
  
end