defmodule Perseids.Order do
  use Perseids.Web, :model

  @collection_name "orders"
  @address_fields ["accept-rules", "city", "country", "email", "name", "phone-number", "post-code", "street", "surname"]

  schema @collection_name do
   field :products,     {:array, :map}
   field :payment,      :string
   field :shipping,     :string
   field :address,      :map
   field :created_at,   :string
   field :customer_id,  :integer
  end

  def changeset(order, params \\ %{}) do
   order
     |> cast(params, [:products, :payment, :shipping, :address, :created_at, :customer_id])
     |> validate_required([:products, :payment, :shipping, :address])
     |> validate_address("shipping", @address_fields)
  end

  def create(params) do
    @collection_name
    |> ORMongo.insert_one(params)
    |> item_response
  end


  def delivery_options(opts \\ [filter: %{}]) do
    %{
      shipping: "shipping" |> ORMongo.find_with_lang(opts) |> list_response,
      payment: "payment" |> ORMongo.find_with_lang(opts) |> list_response
    }
  end

  def find(opts \\ [filter: %{}]) do
    @collection_name
    |> ORMongo.find(opts)
    |> list_response
  end

  def find_one(source_id) do
    @collection_name
    |> ORMongo.find([source_id: source_id])
    |> item_response
  end

  def list_response(list) do
    list
  end

  def item_response(list) do
    list |> List.first
  end

  # Custom validations
  def validate_address(changeset, address_type \\ "shipping", fields) do
    get_field(changeset, :address)[address_type]
    |> Enum.reduce(changeset, &validate_address_field/2)
  end

  def validate_address_field({key, value} = field, changeset) do
    validation_func =
      "validate_" <> key
      |> String.replace("-", "_")
      |> String.to_atom

    case Enum.member?(@address_fields, key) do
      true -> apply(Perseids.Order, validation_func, [value, changeset])
      false -> changeset # will be cool to remove unsupported keys
    end
  end

  def validate_email(value, changeset) do
    case Regex.match?(~r/\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, value) do
      true -> changeset
      false -> add_error(changeset, :address, "Wrong e-mail")
    end
  end

  def validate_name(value, changeset), do: validate_field_length(value, changeset, "Name")
  def validate_surname(value, changeset), do: validate_field_length(value, changeset, "Surname")
  def validate_country(value, changeset), do: validate_field_length(value, changeset, "Country")
  def validate_city(value, changeset), do: validate_field_length(value, changeset, "City")
  def validate_phone_number(value, changeset), do: validate_field_length(value, changeset, "Phone number")
  def validate_post_code(value, changeset), do: validate_field_length(value, changeset, "Post code")
  def validate_street(value, changeset), do: validate_field_length(value, changeset, "Street")

  def validate_field_length(value, changeset, name) do
    case String.length(value) do
      0 -> add_error(changeset, :address, "#{name} is too short")
      _ -> changeset
    end
  end

  def validate_accept_rules(value, changeset) do
    case value do
      true -> changeset
      _ -> add_error(changeset, :address, "You must accept rules to continue")
    end
  end
end
