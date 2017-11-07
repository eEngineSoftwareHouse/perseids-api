defmodule Perseids.Discount do
  use Perseids.Web, :model

  @collection_name "discount"

  def find_one([{:code, code}, {:lang, lang}]) do
    @collection_name
    |> ORMongo.find_with_lang([code: code, lang: lang])
    |> List.first
  end
  
end
