defmodule Perseids.AssetStore do
  @moduledoc """
  Responsible for accepting files and saving them on disk.
  """
  
  @doc """
  Accepts a base64 encoded image saves it locally.

  ## Examples
  
      iex> upload_image(...)
      "http://localhost:4000/dbaaee81609747ba82bea2453cc33b83.png"
      
  """
  
  def upload_image(image_base64) do
    
    # Remove base64 headers and decode the image
    {:ok, image_binary} = Regex.replace(~r/(data:image\/jpeg;base64,|data:image\/png;base64,)/, image_base64, "")
    |> Base.decode64(ignore: :whitespace, padding: false)

    # Generate a unique filename
    filename =
      image_binary
      |> image_extension()
      |> unique_filename()
          
    # Save the image locally here
    Path.absname("#{System.get_env("API_STATIC_FILES_PATH")}#{filename}")
    |> File.write(image_binary, [:binary])
    |> maybe_image_saved?(filename) # Generate the full URL to the newly uploaded image
  end
  
  # Generates a unique filename with a given extension
  defp unique_filename(extension) do
    UUID.uuid4(:hex) <> extension
  end
  
  # Helper functions to read the binary to determine the image extension
  defp image_extension(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _::binary>>), do: ".png"
  defp image_extension(<<0xff, 0xD8, _::binary>>), do: ".jpg"

  defp maybe_image_saved?(:ok, filename), do: {:ok, "#{System.get_env("API_STATIC_FILES_DOMAIN")}/images/uploads/#{filename}"}
  defp maybe_image_saved?({:error, reason}, _filename), do: {:error, reason}
end