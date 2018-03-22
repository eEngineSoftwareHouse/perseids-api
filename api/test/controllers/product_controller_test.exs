defmodule Perseids.ProductControllerTest do
  use Perseids.ConnCase, async: true


  @currently_valid_product "watermelon-splash-low"
  @invalid_product "ThisIsInvalidProduct"

  defp assert_json_response(conn, list, status \\ 200) do 
    assert json_response(conn, status)
    conn |> single_error(list)
  end

  defp single_error(conn, []), do: conn

  defp single_error(conn, [head | tail]) do
    assert conn.resp_body =~ head
    single_error(conn, tail) 
  end

  setup %{conn: conn} do 
    {:ok, conn: conn}
  end

  describe "Product -" do 
    test "test without params", %{conn: conn} do 
      conn
      |> get(product_path(conn, :index))
      |> assert_json_response(["products"])
    end

    test "test with pagination", %{conn: conn} do 
      conn
      |> get(product_path(conn, :index), 
          %{"filter" => %{"categories.id" => ["2"]}, "page" => "2", 
            "select" => "name,price,categories,params,variants.price,variants.name,variants.old_price,source_id,url_key,images"})
      |> assert_json_response(["products", "name","price","categories","params","variants","source_id","url_key","images"])
    end

    test "test with choosed category", %{conn: conn} do 
      conn
      |> get(product_path(conn, :index), 
          %{"filter" => %{"categories.id" => ["28"]}, 
            "select" => "name,price,categories,params,variants.price,variants.name,variants.old_price,source_id,url_key,images"})
      |> assert_json_response(["products", "name", "categories", "params", "url_key", "images"])
    end

    test "test with choosed color", %{conn: conn} do
      conn
        |> get(product_path(conn, :index), 
          %{"filter" => %{"categories.id" => ["2"], "params.color" => ["green"]}, 
            "select" => "name,price,categories,params,variants.price,variants.name,variants.old_price,source_id,url_key,images"})
        |> assert_json_response(["green", "name", "categories", "params", "variants", "source_id", "url_key", "images"])
    end

    test "test with choosed category and selected one pattern", %{conn: conn} do 
      conn
      |> get(product_path(conn, :index), 
          %{"filter" => %{"categories.id" => ["28"], "params.pattern" => ["animals"]}, 
            "select" => "name,price,categories,params,variants.price,variants.name,variants.old_price,source_id,url_key,images"})
      |> assert_json_response(["products", "animals", "name", "categories", "params", "url_key"])
    end

    test "test with choosed category and selected multiple pattern", %{conn: conn} do 
      conn
      |> get(product_path(conn, :index), 
          %{"filter" => %{"categories.id" => ["29"], "params.pattern" => ["winter", "other-stories", "food"]}, 
            "select" => "name,price,categories,params,variants.price,variants.name,variants.old_price,source_id,url_key,images"})
      |> assert_json_response(["products", "food", "winter", "name", "categories", "params", "url_key"])
    end

    test "test with choosed category and selected multiple pattern and one color", %{conn: conn} do 
      conn
      |> get(product_path(conn, :index), 
          %{"filter" => %{"categories.id" => ["29"], "params.color" => ["red"], "params.pattern" => ["winter", "other-stories", "food"]}, 
            "select" => "name,price,categories,params,variants.price,variants.name,variants.old_price,source_id,url_key,images"})
      |> assert_json_response(["products", "food", "winter", "red", "name", "categories", "params", "url_key"])
    end

    test "test with choosed category and selected multiple patterns and multiple colors", %{conn: conn} do 
      conn
      |> get(product_path(conn, :index), 
          %{"filter" => %{"categories.id" => ["27"], "params.color" => ["green", "claret", "orange"], 
            "params.pattern" => ["winter", "food", "black-white", "geometric"]}, 
            "select" => "name,price,categories,params,variants.price,variants.name,variants.old_price,source_id,url_key,images"})
      |> assert_json_response(["products", "food", "winter", "green", "orange", "name", "categories", "params", "url_key"])
    end

    test "test with wrong select case -- with params", %{conn: conn} do
      conn = conn
      |> get(product_path(conn, :index),
          %{"filter" => %{"categories.id" => ["27"], "params.color" => ["green", "claret", "orange"], 
            "params.pattern" => ["winter", "food", "black-white", "geometric"]}, 
            "select" => "xxxx"})
      |> assert_json_response(["winter", "green", "params", "{}"])
      refute conn.resp_body =~ "name"
    end

    test "test with wrong select case -- without params", %{conn: conn} do
      conn = conn
      |> get(product_path(conn, :index), %{"select" => "xxxx"})
      |> assert_json_response(["{}"])
      refute conn.resp_body =~ "name"
    end

    test "test with own select case -- with params", %{conn: conn} do
      conn = conn
      |> get(product_path(conn, :index),
          %{"filter" => %{"categories.id" => ["27"], "params.color" => ["green", "claret", "orange"], 
            "params.pattern" => ["winter", "food", "black-white", "geometric"]}, 
            "select" => "name,price,categories"})
      |> assert_json_response(["name", "price", "params", "categories"])
      refute conn.resp_body =~ "images"
    end

    test "test with own select case -- without params", %{conn: conn} do
      conn = conn
      |> get(product_path(conn, :index), %{"select" => "name,price,categories"})
      |> assert_json_response(["name", "price", "params", "categories"])
      refute conn.resp_body =~ "images"
    end

    test "test show product", %{conn: conn} do
      conn
      |> get(product_path(conn, :show, @currently_valid_product))
      |> assert_json_response(["variants", @currently_valid_product])
    end

    test "test invalid show product", %{conn: conn} do
      conn
      |> get(product_path(conn, :show, @invalid_product))
      |> assert_json_response(["error", "Not found"], 404)
    end  
  end 
end
