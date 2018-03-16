defmodule Perseids.Complaint do
  use Perseids.Web, :model

  @collection_name "complaints"

  schema @collection_name do
   field :email,          :string
   field :order_id,       :string
   field :comment,        :string
   field :base64,          :string
   field :image,          :string
  end

  def changeset(complaint, params \\ %{}) do
    complaint
    |> cast(params, [:email, :order_id, :comment, :base64, :image])
    |> validate_required([:email, :order_id, :comment])
    |> save_image
  end

  def create(params) do
    @collection_name
    |> ORMongo.insert_one(params)
    |> item_response
  end

  def find([_] = opts) do
    @collection_name
    |> ORMongo.find(opts)
    |> list_response
  end

  defp list_response(list), do: list
  defp item_response(list), do: list |> List.first

  def save_image(changeset), do: get_field(changeset, :base64) |> save_image(changeset)

  defp save_image(nil, changeset), do: changeset
  
  defp save_image(base64, changeset) do
    case base64 |> Perseids.AssetStore.upload_image do
      {:ok, image_url} -> changeset |> put_change(:image, image_url)
      {:error, reason} -> add_error(changeset, :image, "Unable to save image on server, reason: #{reason}")
      _ -> add_error(changeset, :image, "Unable to save image on server due to internal error. Check API logs.")
    end
  end

end
