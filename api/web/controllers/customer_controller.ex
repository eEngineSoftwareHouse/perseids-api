defmodule Perseids.CustomerController do
  use Perseids.Web, :controller
  import Perseids.Gettext

  defstruct(
    customer: %{
      email: :required,
      firstname: :required,
      lastname: :required
    },
    password: :required
  ) 

  def info(conn, _params) do
    case conn.assigns[:store_view] |> Magento.customer_info(conn.assigns[:magento_token]) do
        {:ok, response} -> 
          response = Perseids.CustomerHelper.default_lang(response)
          json(conn, response)
        {:error, message} -> 
          conn
          |> put_status(422)
          |> json(%{ errors: [message] })
    end
  end

  def address(conn, %{"address_type" => address}) do
    case conn.assigns[:store_view] |> Magento.address_info(conn.assigns[:magento_token], address) do
        {:ok, response} -> json(conn, response)
        {:error, message} -> 
          conn
          |> put_status(422)
          |> json(%{ errors: [message] })
    end
  end

  def create(conn, params) do
    params 
    |> get_keys
    |> raise_error?
    |> fields_exists?(conn)
    case conn.assigns[:store_view] |> Magento.create_account(params) do
        {:ok, response} -> 
          response = Perseids.CustomerHelper.default_lang(response)
          json(conn, response)
        {:error, message} -> 
          conn
          |> put_status(422)
          |> json(%{ errors: [message] })
    end
  end

  def update(conn, params) do
    case conn.assigns[:store_view] |> Magento.update_account(filtered_params(params), customer_id: conn.assigns[:customer_id], customer_token: conn.assigns[:magento_token], group_id: conn.assigns[:group_id]) do
        {:ok, response} -> 
          response = Perseids.CustomerHelper.default_lang(response)
          json(conn, Map.put_new(response, :session_id, conn.assigns[:session_id]))
        {:error, message} -> 
          conn
          |> put_status(422)
          |> json(%{ errors: [message] })
    end
  end

  def password_reset(conn, %{"email" => _email, "website_id" => _website_id} = params), do: reset_password(true, params, conn)
  def password_reset(conn, %{"password" => password, "password_confirmation" => password_confirmation, "token" => _token, "email" => _email} = params), do: reset_password(password_confirmation == password, params, conn)

  defp reset_password(false, _params, conn), do: conn |> put_status(422) |> json(%{errors: [gettext "Passwords are not the same"]})
  defp reset_password(true, params, conn) do
    case conn.assigns[:store_view] |> Magento.reset_password(params) do
        {:ok, response} -> json(conn, response)
        {:error, message} -> 
          conn
          |> put_status(422)
          |> json(%{ errors: [message] })
    end
  end

  def check_reset_password_token(conn, params) do
    case conn.assigns[:store_view] |> Magento.check_reset_password_token(params) do
        {:ok, response} -> json(conn, response)
        {:error, message} -> conn |> put_status(400) |> json(%{ errors: [message] })
    end
  end

  defp filtered_params(params) do
    whitelisted_params = ~w(website_id lastname firstname addresses)
    %{ "customer" => Enum.reduce(params["customer"], %{}, &(maybe_put_key(&1, &2, whitelisted_params))) }
  end

  defp maybe_put_key({ key, value }, params, whitelisted_params) do
    Enum.member?(whitelisted_params, key)
    |> maybe_put_key(params, key, value)
  end
  
  defp maybe_put_key(true, params, key, value), do: Map.put(params, key, value)
  defp maybe_put_key(false, params, _key, _value), do: params

  defp check_is_valid?(struct, errors \\ []) do
    struct |> Map.to_list |> check_key(errors)
  end

  defp check_key([head | tail], errors) do
    [key | l ] = head |> Tuple.to_list
    value = l |> List.first
    
    if is_map(value) do
      errors = errors ++ check_is_valid?(value, errors)
    else
      errors = errors ++ check(value, key)
    end
    check_key(tail, errors)
  end
  defp check_key([], errors), do: errors

  defp check(:required, name), do: ["Field #{name} is required"]
  defp check(_, _name), do: []

  defp get_keys(params, struct \\ Map.from_struct(Perseids.CustomerController), errors \\ []) when is_map(params) do 
    { struct, errors } = params |> Map.to_list |> get_key(struct, errors)
    struct_errors = struct |> check_is_valid?
    errors ++ struct_errors
  end
    
  defp get_sub_keys(params, struct, errors) when is_map(params) do
      params |> Map.to_list |> get_key(struct, errors)
  end
  
  defp get_key([head | tail], struct, errors) do
    [h | l ] = head |> Tuple.to_list
    key = h |> String.to_atom
    value = l |> List.first

    case Map.has_key?(struct, key) do
      true ->
        current_struct = Map.fetch!(struct, key)
        errors = errors ++ do_validate?(current_struct, value, key)
        if is_map(value) do
          { prev_struct, errors } = get_sub_keys(value, Map.fetch!(struct, key), errors)
        end
        struct = check_struct(prev_struct, struct, key)
      false ->
        errors = errors ++ ["Undefined params key -> #{key}"]
        if is_map(value) do
            { _, errors } = get_sub_keys(value, %{}, errors)
        end
    end
    get_key(tail, struct, errors)
  end
  defp get_key([], struct, errors), do: { struct, errors } 

  defp check_struct(nil, struct, key), do: Map.drop(struct, [key])
  defp check_struct(prev_struct, struct, key) do
    prev_keys = prev_struct |> Map.keys
    error_struct = Map.fetch!(struct, key) |> Enum.reduce(%{}, &(maybe_put_key(&1, &2, prev_keys)))
    replace(struct, key, error_struct)
  end 
  
  defp do_validate?(:required, value, key) when is_binary(value), do: apply(__MODULE__, do_function(key), [value, key])
  defp do_validate?(:optional, value, key) when is_binary(value), do: apply(__MODULE__, do_function(key), [value, key])
  defp do_validate?(:default, _value, _key), do: []
  defp do_validate?(_struct, _value, _key),  do: []
 
  defp do_function(key, string \\ "validate") do
    string <> "_" <> Atom.to_string(key) 
    |> String.replace("-", "_") 
    |> String.to_atom
  end
  
  
  def validate_email(value, name), do: validation(value, name)
  def validate_firstname(value, name), do: validation(value, name)
  def validate_lastname(value, name), do: validation(value, name)
  def validate_password(value, name), do: validation(value, name)
  
  defp validation(value, name) do
    value
    |> String.length
    |> response(name)
  end
  
  defp response(0, name), do: [ "#{name} is too short" ]
  defp response(_other, _name), do: []
  
  defp raise_error?([]), do: false
  defp raise_error?(errors), do: errors
 
  defp fields_exists?(false, _conn), do: nil
  defp fields_exists?(errors, conn), do: conn |> put_status(400) |> json(%{ errors: errors })

  defp replace(map, key, value) do # added function from Map lib (Map.replace!) beacuse is not available in this elixir version.
    case map do
      %{^key => _value} ->
        Map.put(map, key, value)

      %{} ->
        map

      other ->
        :erlang.error({:badmap, other})
    end
  end

end
