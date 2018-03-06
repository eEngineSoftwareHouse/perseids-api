defmodule Perseids.ProductControllerTest do
  use Perseids.ConnCase, async: true

  alias Perseids.ProductController
  alias Perseids.Plugs.CurrentUser

  @currently_valid_product "watermelon-splash-low"
  @invalid_product "ThisIsInvalidProduct"


  describe "Product -" do 
    test "test without params", %{conn: conn} do 
      conn = conn
      |> get(product_path(conn, :index))
      assert json_response(conn, 200)
      assert conn.resp_body =~ "products"
    end

    test "test with pagination", %{conn: conn} do 
      conn = conn
      |> get(product_path(conn, :index), 
          %{"filter" => %{"categories.id" => ["2"]}, "page" => "2", 
            "select" => "name,price,categories,params,variants.price,variants.name,variants.old_price,source_id,url_key,images"})
      assert json_response(conn, 200)
      assert conn.resp_body =~ "products"
    end

    test "test with choosed category", %{conn: conn} do 
      conn = conn
      |> get(product_path(conn, :index), 
          %{"filter" => %{"categories.id" => ["28"]}, 
            "select" => "name,price,categories,params,variants.price,variants.name,variants.old_price,source_id,url_key,images"})
      assert json_response(conn, 200)
      assert conn.resp_body =~ "products"
    end

    test "test with choosed category and selected one pattern", %{conn: conn} do 
      conn = conn
      |> get(product_path(conn, :index), 
          %{"filter" => %{"categories.id" => ["28"], "params.pattern" => ["animals"]}, 
            "select" => "name,price,categories,params,variants.price,variants.name,variants.old_price,source_id,url_key,images"})
      assert json_response(conn, 200)
      assert conn.resp_body =~ "products"
    end

    test "test with choosed category and selected multiple pattern", %{conn: conn} do 
      conn = conn
      |> get(product_path(conn, :index), 
          %{"filter" => %{"categories.id" => ["29"], "params.pattern" => ["winter", "other-stories", "food"]}, 
            "select" => "name,price,categories,params,variants.price,variants.name,variants.old_price,source_id,url_key,images"})
      assert json_response(conn, 200)
      assert conn.resp_body =~ "products"
    end

    test "test with choosed category and selected multiple pattern and one color", %{conn: conn} do 
      conn = conn
      |> get(product_path(conn, :index), 
          %{"filter" => %{"categories.id" => ["29"], "params.color" => ["red"], "params.pattern" => ["winter", "other-stories", "food"]}, 
            "select" => "name,price,categories,params,variants.price,variants.name,variants.old_price,source_id,url_key,images"})
      assert json_response(conn, 200)
      assert conn.resp_body =~ "products"
    end

    test "test with choosed category and selected multiple patterns and multiple colors", %{conn: conn} do 
      conn = conn
      |> get(product_path(conn, :index), 
          %{"filter" => %{"categories.id" => ["27"], "params.color" => ["green", "claret", "orange"], 
            "params.pattern" => ["winter", "food", "black-white", "geometric"]}, 
            "select" => "name,price,categories,params,variants.price,variants.name,variants.old_price,source_id,url_key,images"})
      assert json_response(conn, 200)
      assert conn.resp_body =~ "products"
    end

    test "test show product", %{conn: conn} do
      conn = conn
      |> get(product_path(conn, :show, @currently_valid_product))
      assert json_response(conn, 200)
      assert conn.resp_body =~ "variants"
      assert conn.resp_body =~ @currently_valid_product
    end

    test "test invalid show product", %{conn: conn} do
      conn = conn
      |> get(product_path(conn, :show, @invalid_product))
      assert json_response(conn, 404)
      assert conn.resp_body =~ "Not Found"
    end  
  end 
end
