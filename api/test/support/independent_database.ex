defmodule Perseids.IndependentDatabase do
  ####################################
  ##            IMPORTANT           ##
  ##       AFTER ANY CHANGES HERE   ##
  ## UPDATE DATE IN TEST_HELPER.EXS ##
  ####################################

  #==================================#
  #=         LIST OF ITEMS          =#
  #==================================#
  
  @list_of_discounts [
    %{ "value" => 0, "code" => "TEST_SHIPPING", "type" => "shipping"},
    %{ "value" => 11, "code" => "TEST_FIXED_11", "type" => "fixed"},
    %{ "value" => 50, "code" => "TEST_FIXED_50", "type" => "fixed"},
    %{ "value" => 10, "code" => "TEST_PERCENT", "type" => "percent"}
  ]

  @list_of_products [
    "/product_1.json", #source_id : "434"
    "/product_2.json", #source_id : "51"
    "/product_3.json", #source_id : "111"
    "/product_4.json", #source_id : "119"
    "/product_5.json", #source_id : "143"
    "/product_6.json", #source_id : "203"
    "/product_7.json", #source_id : "107"
    "/product_valid_order.json", #source_id : "455"
    "/product_free_regular.json", #source_id : "458"
    "/product_free_low.json" #source_id : "155"
  ]

  @list_of_tresholds [
    %{"value" => 99.0,"name" => "free_low" },
    %{"value" => 149.0,"name" => "free_shipping" },
    %{"value" => 199.0,"name" => "free_regular" }
  ]

  #==================================#
  #=          METHODS               =#
  #==================================#


  def initialize(lang) do
    Mongo.delete_many(:mongo, "orders", %{})
    Mongo.delete_many(:mongo, "#{lang}_threshold", %{})
    Mongo.delete_many(:mongo, "#{lang}_products", %{})
    Mongo.delete_many(:mongo, "#{lang}_discount", %{})

    create_discount(lang)
    create_products(lang)
    create_thresholds(lang)
  end


  #==================================#
  #=            PRIVATE             =#
  #==================================#

  defp create_discount(lang) do
    @list_of_discounts
    |> Enum.each(&(Mongo.insert_one(:mongo, "#{lang}_discount", &1)))
  end

  defp create_products(lang) do
    @list_of_products
    |> Enum.map(&( lang <> &1))
    |> Enum.reduce([], &decode_single_product(&1, &2))
    |> Enum.each(&(replace_one("#{lang}_products", &1, &1)))
  end

  defp decode_single_product(file, acc) do
    case "/webapps/perseids/test/support/" <> file |> File.read do 
      { :ok, file } -> [ file |> Poison.decode! ] ++ acc
      { :error, _ } -> acc
    end
  end

  defp replace_one(collection, %{ "source_id" => filter }, replacement) do
    Mongo.replace_one(:mongo, collection, %{ "source_id" => filter }, replacement, upsert: true)
  end

  defp create_thresholds(lang) do
    @list_of_tresholds
    |> Enum.each(&(Mongo.insert_one(:mongo, "#{lang}_threshold", &1)))
  end
end