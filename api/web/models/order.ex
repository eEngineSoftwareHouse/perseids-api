defmodule Perseids.Order do
  use Perseids.Web, :model
  import Perseids.Gettext

  alias Perseids.Discount

  @collection_name "orders"
  @address_shipping_required_fields ["city", "country", "name", "phone-number", "post-code", "street", "surname"]
  @address_payment_required_fields ["city", "country", "name", "post-code", "street", "surname", "nip", "company"]

  schema @collection_name do
   field :email,                  :string
   field :products,               {:array, :map}
   field :payment,                :string
   field :shipping,               :string
   field :address,                :map
   field :created_at,             :string
   field :customer_id,            :integer
   field :inpost_code,            :string
   field :redirect_url,           :string
   field :lang,                   :string
   field :currency,               :string
   field :shipping_price,         :integer
   field :data_processing,        :boolean
   field :accept_rules,           :boolean
   field :wholesale,              :boolean
   field :invoice,                :boolean
   field :other_shipping_address, :boolean
   field :discount_code,          :string
   field :comment,                :string
  end

  def changeset(order, params \\ %{}) do
   order
     |> cast(params, [:email, :products, :payment, :shipping, :address, :created_at, :customer_id, :inpost_code, :lang, :currency, :data_processing, :accept_rules, :wholesale, :invoice, :other_shipping_address, :discount_code, :comment])
     |> validate_email
     |> validate_acceptance(:accept_rules)
     |> validate_required([:products, :payment, :shipping, :address])
     |> validate_shipping
     |> validate_required_subfields(address: [:shipping]) # expects address to be map, not list!
     |> validate_required_subfields([address: [:payment]], if: :invoice) # validated only if 'invoice' checkbox is sent
  end

  def create(%{wholesale: true} = params) do
    @collection_name
    |> ORMongo.insert_one(append_proper_wholesale_shipping_and_payment(params))
    |> item_response
  end

  def create(%{payment: "payu-pre"} = params) do
    @collection_name
    |> ORMongo.insert_one(update_shipping_and_payment_info(params))
    |> item_response
    |> PayU.place_order
  end

  def create(%{payment: "paypal-pre"} = params) do
    @collection_name
    |> ORMongo.insert_one(update_shipping_and_payment_info(params))
    |> item_response
    |> PayPal.create_payment
  end

  def create(params) do
    @collection_name
    |> ORMongo.insert_one(update_shipping_and_payment_info(params))
    |> item_response
  end

  def append_proper_wholesale_shipping_and_payment(params) do
    products_count = products_count(params)
    shipping = get_wholesale_shipping_for(params.address["shipping"]["country"], products_count, params.lang).shipping |> List.first
    case shipping do
      nil -> raise "Wholesale shipping for such order doesn't exist"
      shipping -> 
        Perseids.Shipping.find_one(source_id: shipping["source_id"], lang: params.lang) 
        Map.put(params, :shipping_price, shipping["price"])
        |> Map.put(:shipping, shipping["source_id"])
        |> Map.put_new(:shipping_code, shipping["code"])
        |> Map.put(:payment_code, "banktransfer")
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

  def validate_email(changeset) do
    get_field(changeset, :email)
    |> validate_email(changeset)
  end

  def validate_email("", changeset), do: add_error(changeset, :email, gettext "E-mail can't be blank")
  def validate_email(nil, changeset), do: add_error(changeset, :email, gettext "E-mail can't be blank")
  def validate_email(email, changeset) do
    case Regex.match?(~r/\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, email) do
      true -> changeset
      false -> add_error(changeset, :email, gettext "Wrong e-mail")
    end
  end

  def validate_required_subfields(changeset, subfields, if: key ) do
    case get_field(changeset, key) do
      true -> validate_required_subfields(changeset, subfields, optional: true)
      _ -> changeset
    end
  end

  def validate_required_subfields(changeset, [], _optional), do: changeset

  def validate_required_subfields(changeset, [head | tail], optional \\ [optional: false]) do
    { key, required_subfields } = head
    subfields = get_field(changeset, key) |> Helpers.atomize_keys
    
    subfield_present?(changeset, subfields, required_subfields, key, optional)
    |> validate_required_subfields(tail)
  end
  

  def subfield_present?(changeset, nil, _required_subfields, _key, _optional), do: changeset
  def subfield_present?(changeset, _subfields, [], _key, _optional),            do: changeset

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

  def maybe_optional_subfield(changeset, _key, _message, optional: true), do: changeset
  def maybe_optional_subfield(changeset, key, message, optional: false), do: add_error(changeset, key, message)

  def validate_shipping(changeset) do
    case get_field(changeset, :shipping) do
      "paczkomat-PL" -> if get_field(changeset, :inpost_code), do: changeset, else: add_error(changeset, :inpost_code, gettext "You must select parcel locker")
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
      missing_fields -> Enum.reduce(missing_fields, changeset, fn(field, acc) -> add_error(acc, :address, "#{String.capitalize(address_type)} - #{field}" <> gettext "field is required") end)
    end
  end

  def validate_address_field({key, value} = _field, changeset, address_type) do
    validation_func =
      "validate_" <> key
      |> String.replace("-", "_")
      |> String.to_atom

    validate_single_field(address_type, validation_func, value, changeset, key)
  end

  def validate_single_field("Shipping", validation_func, value, changeset, key) do
    case Enum.member?(@address_shipping_required_fields, key) do
      true -> apply(Perseids.Order, validation_func, [value, changeset, gettext "Shipping"])
      false -> changeset # will be cool to remove unsupported keys
    end
  end

  def validate_single_field("Payment", validation_func, value, changeset, key) do
    case Enum.member?(@address_payment_required_fields, key) do
      true -> apply(Perseids.Order, validation_func, [value, changeset, gettext "Payment"])
      false -> changeset # will be cool to remove unsupported keys
    end
  end

  def get_required_fields_for("shipping"), do: @address_shipping_required_fields
  def get_required_fields_for("payment"), do: @address_payment_required_fields
  def get_required_fields_for(_other), do: []

  
  def validate_name(value, changeset, address_type),          do: validate_field_length(value, changeset, address_type <> gettext " - name")
  def validate_surname(value, changeset, address_type),       do: validate_field_length(value, changeset, address_type <> gettext " - surname")
  def validate_country(value, changeset, address_type),       do: validate_field_length(value, changeset, address_type <> gettext " - country")
  def validate_city(value, changeset, address_type),          do: validate_field_length(value, changeset, address_type <> gettext " - city")
  def validate_post_code(value, changeset, address_type),     do: validate_field_length(value, changeset, address_type <> gettext " - post code")
  def validate_street(value, changeset, address_type),        do: validate_field_length(value, changeset, address_type <> gettext " - street")
  def validate_company(value, changeset, address_type),       do: validate_field_length(value, changeset, address_type <> gettext " - company")

  def validate_phone_number(value, changeset, address_type) do
    changeset = validate_field_length(value, changeset, address_type <> gettext " - phone number")
    case Regex.match?(~r/^[0-9]*$/, value) do
      true -> changeset
      _ -> add_error(changeset, :address, "#{address_type} - " <> gettext "phone number should contain only numbers")
    end
  end

  def validate_nip(value, changeset, address_type) do
    changeset = validate_field_length(value, changeset, address_type <> " - nip")
    case Regex.match?(~r/^[0-9]*$/, value) do
      true -> changeset
      _ -> add_error(changeset, :address, "#{address_type} - " <> gettext "nip should contain only numbers")
    end
  end
  
  def validate_field_length(value, changeset, name) do
    case String.length(value) do
      0 -> add_error(changeset, :address, "#{name} " <> gettext "is too short")
      _ -> changeset
    end
  end

  def validate_accept_rules(value, changeset, _address_type) do
    case value do
      true -> changeset
      _ -> add_error(changeset, :address, gettext "You must accept rules to continue")
    end
  end

  # Additional order calculations
  defp update_shipping_and_payment_info(params) do
    shipping = Perseids.Shipping.find_one(source_id: params.shipping, lang: params.lang) 
    payment = Perseids.Payment.find_one(source_id: params.payment, lang: params.lang) 
    
    update_products(params, params.products, params.lang)
    |> Map.put_new(:order_total_price, calc_order_total(params.products, params[:discount_code], params.lang))
    |> add_shipping_price(shipping, params.lang)
    |> Map.put_new(:shipping_code, shipping["code"])
    |> Map.put_new(:shipping_name, shipping["name"])
    |> Map.put_new(:payment_name, payment["name"])
    |> Map.put_new(:payment_code, payment["code"])
  end

  defp update_products(params, products, lang) do
    new_products = products
    |> Enum.reduce([], &update_product(&1, &2, lang))
    Map.put(params, :products, new_products)
  end

  defp calc_order_total(products, discount_code, lang) do
    products
    |> Enum.reduce(0, &get_product_price(&1, &2, lang))
    |> maybe_discount(Discount.find_one(code: discount_code, lang: lang))
  end

  defp maybe_discount(order_total, nil), do: order_total
  defp maybe_discount(order_total, discount) do
    %{"value" => discount_value } = discount
    order_total - (order_total * (discount_value * 0.01))
  end

  defp add_shipping_price(%{order_total_price: order_total_price} = order, shipping, lang) do
    threshold = get_threshold(lang)
    if order_total_price >= threshold do
      Map.put(order, :shipping_price, 0)
    else
      Map.put(order, :shipping_price, get_default_shipping_price(shipping))
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
    Perseids.Product.find_one(source_id: product["id"], lang: lang)["price"][product["variant_id"]]
  end

  # Total product price
  defp get_product_price(product, acc, lang) do
    acc + (product["count"] * (Perseids.Product.find_one(source_id: product["id"], lang: lang)["price"][product["variant_id"]]))
  end

  defp update_product(product, acc, lang) do
    price = Perseids.Product.find_one(source_id: product["id"], lang: lang)["price"][product["variant_id"]]
    updated_product = product
    |> Map.put_new("price", price)
    |> Map.put_new("total_price", price * product["count"])

    List.insert_at(acc, -1, updated_product)
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
