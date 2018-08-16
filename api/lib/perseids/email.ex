defmodule Perseids.Email do
  use Bamboo.Phoenix, view: Perseids.EmailView

  def contact_form(%{"from" => from, "content" => content} = _params) do
    new_email()
    |> to(Application.get_env(:perseids, :contact_form)[:email])
    |> from(from)
    |> subject("Wiadomość z formularza kontaktowego ManyMornings")
    |> text_body(content)
  end

  def complaint_form(%{"email" => from, "exported_id" => exported_id, "_id" => _complaint_id, "comment" => comment } = complaint) do
    new_email()
    |> to(Application.get_env(:perseids, :contact_form)[:email])
    |> from(from)
    |> subject("Reklamacja (nr zam. #{exported_id}) - ManyMornings.com")
    |> maybe_image_in_html_body?(complaint["image"], exported_id, comment)
  end

  defp maybe_image_in_html_body?(conn, nil, exported_id, comment) do
    conn
    |> html_body("
      <h1>Reklamacja do zamówienia nr #{exported_id}</h1>
      <p>#{comment}</p>
    ")
  end

  defp maybe_image_in_html_body?(conn, image_url, exported_id, comment) do
    conn
    |> html_body("
      <h1>Reklamacja do zamówienia nr #{exported_id}</h1>
      <p>#{comment}</p>
      <img src='#{image_url}' />
    ")
  end
end
