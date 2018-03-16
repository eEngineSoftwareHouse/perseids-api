defmodule Perseids.Email do
  use Bamboo.Phoenix, view: Perseids.EmailView

  def contact_form(%{"from" => from, "content" => content} = _params) do
    new_email()
    |> to(Application.get_env(:perseids, :contact_form)[:email])
    |> from(from)
    |> subject("Wiadomość z formularza kontaktowego ManyMornings")
    |> text_body(content)
  end

  def compliant_form(%{"email" => from, "order_id" => order_id, "image" => image, "_id" => complaint_id, "comment" => comment } = _params) do
    new_email()
    |> to(Application.get_env(:perseids, :contact_form)[:email])
    |> from(from)
    |> subject("Reklamacja - ManyMornings.com")
    |> html_body("
      <h1>Reklamacja do zamówienia nr #{order_id}</h1>
      <p>#{comment}</p>
      <img src='#{image}' />
    ")
  end
end
