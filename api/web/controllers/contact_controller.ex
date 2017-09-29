defmodule Perseids.ContactController do
  use Perseids.Web, :controller
  alias Perseids.Email
  alias Perseids.Mailer

  def contact_form(conn, %{"from" => _from, "content" => _content} = params) do
    Email.contact_form(params)
    |> Mailer.deliver_later

    json(conn, "ok")
  end

  def contact_form(conn, _params), do: json(conn, %{errors: "Lack of `from` or `content` fields in request"})
end
