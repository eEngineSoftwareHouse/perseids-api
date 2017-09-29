defmodule Perseids.Parsers.JSON do
  @moduledoc """
  Parses JSON request body, and optionally copies the raw body

  Copies raw body to `:raw_body` private assign
  """

  @behaviour Plug.Parsers
  alias Plug.Conn

  def parse(conn, "application", "json", _headers, opts) do
    case Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        {:ok, decoded_body} = Poison.decode(body)
        {:ok, decoded_body, Plug.Conn.put_private(conn, :raw_body, body)}
      {:more, _data, conn} ->
        {:error, :too_large, conn}
    end
  end

  def parse(conn, _type, _subtype, _headers, _opts) do
    {:next, conn}
  end
end
