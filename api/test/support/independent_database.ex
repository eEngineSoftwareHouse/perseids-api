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
    [
      "#{lang}/product_1.json",
      "#{lang}/product_2.json",
      "#{lang}/product_3.json",
      "#{lang}/product_free_regular.json",
      "#{lang}/product_free_low.json"
    ]
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
    Mongo.delete_many(:mongo, "#{lang}_threshold", %{})
    [
      %{"value" => 99.0,"name" => "free_low" },
      %{"value" => 149.0,"name" => "free_shipping" },
      %{"value" => 199.0,"name" => "free_regular" }
    ]
    |> Enum.each(&(Mongo.insert_one(:mongo, "#{lang}_threshold", &1)))
  end
end