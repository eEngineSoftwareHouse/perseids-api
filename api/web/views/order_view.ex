defmodule Perseids.OrderView do
  def render("order.json", %{order: order}) do
      order_json(order)
  end

  def render("orders.json", %{orders: orders, count: count}) do
    %{
      count: count,
      orders: Enum.map(orders, &order_json/1)
    }
  end

  def render("index.json", %{shipping: shipping, payment: payment}) do
    %{
      shipping: Enum.map(shipping, &shipping_json/1),
      payment: Enum.map(payment, &payment_json/1)
    }
  end

  def render("errors.json", %{changeset: changeset}) do
    %{
      errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)
    }
  end


  defp shipping_json(shipping) do
    %{
      name: shipping["name"],
      source_id: shipping["source_id"],
      code: shipping["code"],
      pay_type: shipping["pay_type"],
      price: shipping["price"],
      price_formatted: shipping["price_formatted"]
    }
  end

  defp payment_json(payment) do
    %{
      name: payment["name"],
      source_id: payment["source_id"],
      code: payment["code"],
      pay_type: payment["pay_type"],
      price: payment["price"],
      price_formatted: payment["price_formatted"],
      options: payment["options"]
    }
  end

  defp order_json(order) do
    %{
      products: order["products"],
      payment: order["payment"],
      shipping: order["shipping"],
      address: order["address"],
      created_at: order["created_at"],
      customer_id: order["customer_id"]
    }
  end
end