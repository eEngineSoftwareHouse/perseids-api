defmodule Perseids.AssetController do
  use Perseids.Web, :controller
  
  def create(conn, %{"image" => image_base64}) do
    url = Perseids.AssetStore.upload_image(image_base64)
    
    conn
    |> put_status(201)
    |> json(%{"url" => url})
  end
end