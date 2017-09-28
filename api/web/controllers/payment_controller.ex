defmodule Perseids.PaymentController do
  use Perseids.Web, :controller

  def notify(conn, params) do
    IO.puts "PaymentController#notify"
    IO.inspect params
    json(conn, %{params: params})
  end
end
