defmodule Perseids.Email do
  use Bamboo.Phoenix, view: Perseids.EmailView

  def contact_form(%{"from" => from, "content" => content} = _params) do
    new_email()
    |> to(Application.get_env(:perseids, :contact_form)[:email])
    |> from(from)
    |> subject("Wiadomość z formularza kontaktowego ManyMornings")
    |> text_body(content)
  end
end
