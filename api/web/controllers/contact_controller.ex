defmodule Perseids.ContactController do
  use Perseids.Web, :controller

  alias Perseids.ComplaintView
  alias Perseids.Email
  alias Perseids.Mailer
  alias Perseids.Complaint

  def contact_form(conn, %{"from" => _from, "content" => _content} = params) do
    Email.contact_form(params)
    |> Mailer.deliver_later

    json(conn, "ok")
  end

  def complaint_form(conn, params) do
    changeset = Complaint.changeset(%Perseids.Complaint{}, params)
    if changeset.valid? do
      conn 
      |> put_view(ComplaintView)
      |> render("complaint.json", complaint: Complaint.create(changeset.changes))
    else
      conn 
      |> put_status(401)
      |> put_view(ComplaintView)
      |> render("errors.json", changeset: changeset)
    end
  end

  def contact_form(conn, _params), do: json(conn, %{errors: gettext "Lack of `from` or `content` fields in request"})
end