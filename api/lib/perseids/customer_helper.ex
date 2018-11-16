defmodule Perseids.CustomerHelper do

  def default_lang(customer) do
    # Keys are collection prefixes in Mongo, and values are corresponding shop_view codes
    # e.g. Magento shop_view code "EN USD" could map to "en_usd" to create en_usd_products collection in Mongo
    prefixes_map = %{
        "plpl" => "pl_pln",
        "eneu" => "en_eur",
        "engbp" => "en_gbp",
        "enus" => "en_usd",
        "default" => "pl_pln"
    }

    customer
    |> Map.put_new(:default_lang, prefixes_map[customer["store_code"]])
  end

  def wholesale_debt_limit(%{ "is_wholesaler" => true, "email" => email } = customer_data) do
    { _key, response } = MicroAdmin.wholesaler_limit(email)

    customer_data
    |> Map.put(:debt_amount_left, response["debt_amount_left"] || 0)
    |> Map.put(:debt_limit, response["debt_limit"] || 0)
  end

  def wholesale_debt_limit(customer_data), do: customer_data
end
