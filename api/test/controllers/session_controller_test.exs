defmodule Perseids.SessionControllerTest do
  use Perseids.ConnCase, async: true

  @valid_credentials %{"email" => "szymon.ciolkowski@eengine.pl", "password" => "Tajnafraza12"}
  
  defp logged_in(conn), do: conn |> Perseids.ConnCase.login(@valid_credentials, "pl_pln")
  defp logout(conn), do: conn |> Perseids.ConnCase.logout(%{})

  setup %{conn: conn} do
    conn = put_req_header(conn, "content-type", "application/json")
    {:ok, conn: conn}
  end
  describe "Session -" do
    test "create/2", %{conn: conn} do
      conn = conn
      |> logged_in
      assert get_req_header(conn, "authorization") != nil
      assert conn.assigns.currency == "PLN"
      assert conn.assigns.lang == "pl_pln"
      assert conn.assigns.locale == "pl"
      assert conn.assigns.store_view == "plpl"
    end

    test "destroy", %{conn: conn} do
      conn = conn
      |> logged_in
      assert get_req_header(conn, "authorization") != nil
      conn = logout(conn)
      assert json_response(conn, 200)
      assert conn.resp_body =~ "true"
    end
  end
end
