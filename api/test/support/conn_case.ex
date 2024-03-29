defmodule Perseids.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import Perseids.Router.Helpers

      # The default endpoint for testing
      @endpoint Perseids.Endpoint
    end
  end

  setup do
    conn = Phoenix.ConnTest.build_conn()
    |> Plug.Conn.put_req_header("accept", "application/json")

    {:ok, conn: conn}
  end
  
  def login(conn, %{"email" => _email, "password" => _password} = credentials, lang) do
    conn = conn |> guest(lang)

    %Plug.Conn{resp_body: response} = Perseids.SessionController.create(conn, credentials)

    conn 
    |> Plug.Conn.put_req_header("authorization", Poison.decode!(response)["session_id"])
    |> Perseids.Plugs.CurrentUser.call(%{})
  end

  def guest(conn, lang) do
    conn
    |> Plug.Conn.put_req_header("client-language", lang)
    |> Perseids.Plugs.Language.call(%{})
  end

  def logout(conn, params) do
    conn
    |> Perseids.SessionController.destroy(params)
  end

  def check_json_response(conn, [], _conditions), do: conn
  def check_json_response(conn, [head | tail], :assert) do 
    assert conn.resp_body =~ head
    check_json_response(conn, tail, :assert) 
  end
  def check_json_response(conn, [head | tail], :refute) do 
    refute conn.resp_body =~ head
    check_json_response(conn, tail, :refute) 
  end
end
