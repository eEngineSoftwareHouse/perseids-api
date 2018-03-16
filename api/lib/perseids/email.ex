defmodule Perseids.Email do
  use Bamboo.Phoenix, view: Perseids.EmailView

  def contact_form(%{"from" => from, "content" => content} = _params) do
    new_email()
    |> to(Application.get_env(:perseids, :contact_form)[:email])
    |> from(from)
    |> subject("Wiadomość z formularza kontaktowego ManyMornings")
    |> text_body(content)
  end

  def compliant_form(%{"email" => from, "order_id" => order_id, "_id" => complaint_id, "comment" => comment } = complaint) do
    new_email()
    |> to(Application.get_env(:perseids, :contact_form)[:email])
    |> from(from)
    |> subject("Reklamacja (nr zam. #{order_id}) - ManyMornings.com")
    |> maybe_image_in_html_body?(complaint["image"], order_id, comment)
  end

  defp maybe_image_in_html_body?(conn, nil, order_id, comment) do
    conn
    |> html_body("
      <h1>Reklamacja do zamówienia nr #{order_id}</h1>
      <p>#{comment}</p>
    ")
  end

  defp maybe_image_in_html_body?(conn, image_url, order_id, comment) do
    conn
    |> html_body("
      <h1>Reklamacja do zamówienia nr #{order_id}</h1>
      <p>#{comment}</p>
      <img src='#{image_url}' />
    ")
  end
end
