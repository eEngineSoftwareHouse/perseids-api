defmodule Perseids.CustomerController do
  use Perseids.Web, :controller

  def info(conn, params) do
    case Magento.customer_info(conn.assigns[:magento_token]) do
        {:ok, response} -> json(conn, response)
        {:error, message} -> json(conn, %{ errors: [message] })
    end
  end

  def create(conn, params) do
    case Magento.create_account(params) do
        {:ok, response} -> json(conn, response)
        {:error, message} -> json(conn, %{ errors: [message] })
    end
  end

  def update(conn, params) do
    case Magento.update_account(params, customer_id: conn.assigns[:customer_id]) do
        {:ok, response} -> json(conn, Map.put_new(response, :session_id, conn.assigns[:session_id]))
        {:error, message} -> json(conn, %{ errors: [message] })
    end
  end

end
