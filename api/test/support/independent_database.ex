defmodule Perseids.IndependentDatabase do
  ####################################
  ##            IMPORTANT           ##
  ##       AFTER ANY CHANGES HERE   ##
  ## UPDATE DATE IN TEST_HELPER.EXS ##
  ####################################

  def initialize(lang) do
    Mongo.delete_many(:mongo, "orders", %{})
    create_discount(lang)
    create_products(lang)
    create_thresholds(lang)
  end

  defp create_discount(lang) do
    Mongo.delete_many(:mongo, "#{lang}_discount", %{})
    [
      %{ "value" => 0, "code" => "TEST_SHIPPING", "type" => "shipping"},
      %{ "value" => 11, "code" => "TEST_FIXED_11", "type" => "fixed"},
      %{ "value" => 50, "code" => "TEST_FIXED_50", "type" => "fixed"},
      %{ "value" => 10, "code" => "TEST_PERCENT", "type" => "percent"}
    ]
    |> Enum.each(&(Mongo.insert_one(:mongo, "#{lang}_discount", &1)))
  end

  defp create_products(lang) do 
    Mongo.delete_many(:mongo, "#{lang}_products", %{})
    [
      "#{lang}/product_1.json",
      "#{lang}/product_2.json",
      "#{lang}/product_3.json",
      "#{lang}/product_free_regular.json",
      "#{lang}/product_free_low.json"
    ]
    |> Enum.map(&decode_single_product(&1))
    |> Enum.each(&(Mongo.insert_one(:mongo, "#{lang}_products", &1)))
  end

  defp decode_single_product(file) do
    case "/webapps/perseids/test/support/" <> file |> File.read do 
      { :ok, file } -> file |> Poison.decode!
      { :error, _ } -> []
    end
  end

  defp create_thresholds(lang) do
    Mongo.delete_many(:mongo, "#{lang}_threshold", %{})
    [
      %{"value" => 99.0,"name" => "free_low" },
      %{"value" => 149.0,"name" => "free_shipping" },
      %{"value" => 199.0,"name" => "free_regular" }
    ]
    |> Enum.each(&(Mongo.insert_one(:mongo, "#{lang}_threshold", &1)))
  end

    # Mongo.update_one(:mongo, "#{lang}_products", %{"source_id" =>  "155"}, 
    #   %{"$set" =>  
    #     %{"free" =>  "free_low",
    #       "variants.0.price" =>  0,
    #       "variants.1.price" =>  0,
    #       "variants.2.price" =>  0,
    #       "price.152" =>  0,
    #       "price.153" =>  0,
    #       "price.154" =>  0
    #   }}, upsert: true )
    # Mongo.update_one(:mongo, "#{lang}_products", %{"source_id" =>  "458"}, 
    #   %{"$set" =>  
    #     %{"free" =>  "free_regular",
    #       "variants.0.price" =>  0,
    #       "variants.1.price" =>  0,
    #       "variants.2.price" =>  0,
    #       "price.456" =>  0,
    #       "price.457" =>  0,
    #       "price.455" =>  0
    #   }}, upsert:  true )

    # {:ok, mongo: "ok"}

end