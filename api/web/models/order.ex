defmodule Perseids.Order do
  use Perseids.Web, :model

  @collection_name "orders"
  @address_shipping_required_fields ["city", "country", "email", "name", "phone-number", "post-code", "street", "surname"]
  @address_payment_required_fields ["city", "country", "email", "name", "phone-number", "post-code", "street", "surname", "nip", "company"]

  schema @collection_name do
   field :products,           {:array, :map}
   field :payment,            :string
   field :shipping,           :string
   field :address,            :map
   field :created_at,         :string
   field :customer_id,        :integer
   field :inpost_code,        :string
   field :redirect_url,       :string
   field :lang,               :string
   field :currency,           :string
   field :shipping_price,     :integer
   field :data_processing,    :boolean
   field :accept_rules,       :boolean
   field :wholesale,          :boolean
  end

  def changeset(order, params \\ %{}) do
   order
     |> cast(params, [:products, :payment, :shipping, :address, :created_at, :customer_id, :inpost_code, :lang, :currency, :data_processing, :accept_rules, :wholesale])
     |> validate_acceptance(:accept_rules)
     |> validate_required([:products, :payment, :shipping, :address])
     |> validate_shipping
     |> validate_required_subfields(address: [:shipping]) # expects address to be map, not list!
     |> validate_required_subfields([address: [:payment, :customer]], optional: true) # validated only if 'payment' or 'customer' are sent
  end

  def create(%{wholesale: true} = params) do
    @collection_name
    |> ORMongo.insert_one(append_proper_wholesale_shipping(params))
    |> item_response
  end

  def create(%{payment: "payu-pre"} = params) do
    @collection_name
    |> ORMongo.insert_one(append_shipping_price(params))
    |> item_response
    |> PayU.place_order
  end

  def create(%{payment: "paypal-pre"} = params) do
    @collection_name
    |> ORMongo.insert_one(append_shipping_price(params))
    |> item_response
    |> PayPal.create_payment
  end

  def create(params) do
    @collection_name
    |> ORMongo.insert_one(append_shipping_price(params))
    |> item_response
  end

  def append_proper_wholesale_shipping(params) do
    products_count = products_count(params)
    shipping = get_wholesale_shipping_for(params.address["shipping"]["country"], products_count, params.lang).shipping |> List.first
    case shipping do
      nil -> raise "Wholesale shipping for such order doesn't exist"
      shipping -> 
        Perseids.Shipping.find_one(source_id: shipping["source_id"], lang: params.lang) 
        Map.put(params, :shipping_price, shipping["price"])
        |> Map.put(:shipping, shipping["source_id"])
        |> Map.put(:payment, "banktransfer-pre")
    end
  end

  def delivery_options(opts \\ [where: %{}]) do
    payment_opts = Keyword.drop(opts, [:where])
    %{
      shipping: "shipping" |> ORMongo.find_with_lang(opts) |> list_response,
      payment: "payment" |> ORMongo.find_with_lang(payment_opts) |> list_response
    }
  end

  def find(opts \\ [filter: %{}]) do
    @collection_name
    |> ORMongo.find(opts)
    |> list_response
  end

  def find_one(object_id) do
    @collection_name
    |> ORMongo.find([_id: object_id])
    |> item_response
  end

  def update(id, new_value) do
    @collection_name |> ORMongo.update_one(%{"_id" => BSON.ObjectId.decode!(id)}, new_value)
  end

  defp list_response(list), do: list
  defp item_response(list), do: list |> List.first

  # Custom validations
  def validate_required_subfields(changeset, [], optional: true), do: changeset
  def validate_required_subfields(changeset, [], optional: false), do: changeset
  
  def validate_required_subfields(changeset, [head | tail], optional \\ [optional: false]) do
    { key, required_subfields } = head
    subfields = get_field(changeset, key) |> Helpers.atomize_keys
    
    subfield_present?(changeset, subfields, required_subfields, key, optional)
    |> validate_required_subfields(tail)
  end

  def subfield_present?(changeset, nil, _required_subfields, key, _optional), do: changeset
  def subfield_present?(changeset, subfields, [], key, _optional),            do: changeset

  def subfield_present?(changeset, subfields, [ head | tail ], key, optional) do
    validation_func = "validate_" <> Atom.to_string(key) 
    |> String.replace("-", "_") 
    |> String.to_atom

    changeset = case subfields |> Map.has_key?(head) do
      false -> maybe_optional_subfield(changeset, key, "#{head |> Atom.to_string |> String.capitalize} must exist", optional)
      true -> apply(Perseids.Order, validation_func, [changeset, Atom.to_string(head)])
    end

    subfield_present?(changeset, subfields, tail, key, optional)
  end

  def maybe_optional_subfield(changeset, key, message, optional: true), do: changeset
  def maybe_optional_subfield(changeset, key, message, optional: false), do: add_error(changeset, key, message)

  def validate_shipping(changeset) do
    case get_field(changeset, :shipping) do
      "inpost" -> validate_required(changeset, [:inpost_code]) # validate presence of box machine code if "inpost" shipping
      _ -> changeset
    end
  end

  def validate_address(changeset, address_type \\ "shipping") do
    changeset = check_required_address_fields(changeset, address_type)
    get_field(changeset, :address)[address_type]
    |> Enum.reduce(changeset, fn(elem, acc) -> validate_address_field(elem, acc, String.capitalize(address_type)) end)
  end

  def check_required_address_fields(changeset, address_type) do
    case get_required_fields_for(address_type) -- Map.keys(get_field(changeset, :address)[address_type]) do
      [] -> changeset
      missing_fields -> Enum.reduce(missing_fields, changeset, fn(field, acc) -> add_error(acc, :address, "#{String.capitalize(address_type)} - #{field} field is required") end)
    end
  end

  def validate_address_field({key, value} = _field, changeset, address_type) do
    validation_func =
      "validate_" <> key
      |> String.replace("-", "_")
      |> String.to_atom

    case Enum.member?(@address_shipping_required_fields, key) do
      true -> apply(Perseids.Order, validation_func, [value, changeset, address_type])
      false -> changeset # will be cool to remove unsupported keys
    end
  end

  def get_required_fields_for("shipping"), do: @address_shipping_required_fields
  def get_required_fields_for("payment"), do: @address_payment_required_fields
  def get_required_fields_for(_other), do: []

  def validate_email(value, changeset, address_type) do
    case Regex.match?(~r/\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, value) do
      true -> changeset
      false -> add_error(changeset, :address, address_type <> " - wrong e-mail")
    end
  end

  def validate_name(value, changeset, address_type),          do: validate_field_length(value, changeset, address_type <> " - name")
  def validate_surname(value, changeset, address_type),       do: validate_field_length(value, changeset, address_type <> " - surname")
  def validate_country(value, changeset, address_type),       do: validate_field_length(value, changeset, address_type <> " - country")
  def validate_city(value, changeset, address_type),          do: validate_field_length(value, changeset, address_type <> " - city")
  def validate_post_code(value, changeset, address_type),     do: validate_field_length(value, changeset, address_type <> " - post code")
  def validate_street(value, changeset, address_type),        do: validate_field_length(value, changeset, address_type <> " - street")

  def validate_phone_number(value, changeset, address_type) do
    changeset = validate_field_length(value, changeset, address_type <> " - phone number")
    case Regex.match?(~r/^[0-9]*$/, value) do
      true -> changeset
      _ -> add_error(changeset, :address, "#{address_type} - phone number should contain only numbers")
    end
  end
  
  def validate_field_length(value, changeset, name) do
    case String.length(value) do
      0 -> add_error(changeset, :address, "#{name} is too short")
      _ -> changeset
    end
  end

  def validate_accept_rules(value, changeset, address_type) do
    case value do
      true -> changeset
      _ -> add_error(changeset, :address, "You must accept rules to continue")
    end
  end

  # Additional order calculations
  defp append_shipping_price(params) do
    shipping = Perseids.Shipping.find_one(source_id: params.shipping, lang: params.lang) 
    Map.put(params, :shipping_price, calc_shipping_price(params.products, shipping, params.lang))
  end

  defp calc_shipping_price(products, shipping, lang) do
    products
    |> Enum.map(&get_product_price(&1, lang) * &1["count"])
    |> products_price_sum
    |> check_free_shipping(shipping, lang)
  end

  defp check_free_shipping(order_total, shipping, lang) do
    default_shipping_price = get_default_shipping_price(shipping)
    threshold = get_threshold(lang)
    if order_total >= threshold do
      0
    else
      default_shipping_price
    end
  end

  defp get_threshold(lang) do
    Perseids.Threshold.find(lang: lang)
    |> item_response
    |> get_value
  end

  defp get_value(threshold) do
    threshold["value"]
  end

  defp get_default_shipping_price(shipping) do
    shipping["price"]
    |> format_price
  end

  defp get_product_price(product, lang) do
    Perseids.Product.find_one(source_id: product["id"], lang: lang)["price"]
    |> List.first
  end

  defp products_price_sum(prices_list) do
    prices_list
    |> Enum.sum
    |> format_price
  end

  defp format_price(price) do
    price
    |> Kernel./(1) # be sure that price is INT
    |> Float.round(2)
  end

  def get_wholesale_shipping_for(country, count, lang) do
    wholesale_shipping_params = [
      %{ 
        "country" => country, 
        "wholesale" => true, 
        "to" => %{ "$gte" => count },
        "from" => %{ "$lte" => count } 
      }
    ]

    delivery_options([where: wholesale_shipping_params, lang: lang])
  end

  defp products_count(params), do: params.products |> Enum.reduce(0, &(&1["count"] + &2))
end
