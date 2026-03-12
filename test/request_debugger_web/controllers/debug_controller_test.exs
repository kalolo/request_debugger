defmodule RequestDebuggerWeb.CatchControllerTest do
  use RequestDebuggerWeb.ConnCase

  setup do
    RequestDebugger.RequestStore.clear()
    :ok
  end

  test "GET /catch/* returns JSON ok", %{conn: conn} do
    conn = get(conn, "/catch/v1/api/hello")
    assert json_response(conn, 200) == %{"status" => "ok"}
  end

  test "POST /catch/* with JSON body returns ok and stores request", %{conn: conn} do
    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post("/catch/v2/api/something", Jason.encode!(%{key: "value"}))

    assert json_response(conn, 200) == %{"status" => "ok"}

    [stored] = RequestDebugger.RequestStore.list()
    assert stored.method == "POST"
    assert stored.request_path == "/catch/v2/api/something"
    assert stored.raw_body == ~s({"key":"value"})
  end

  test "GET /catch/* with query params stores them", %{conn: conn} do
    get(conn, "/catch/test?foo=bar&baz=qux")

    [stored] = RequestDebugger.RequestStore.list()
    assert stored.query_params == %{"foo" => "bar", "baz" => "qux"}
  end

  test "stores custom headers", %{conn: conn} do
    conn
    |> put_req_header("x-custom-header", "test-value")
    |> get("/catch/anything")

    [stored] = RequestDebugger.RequestStore.list()
    assert Enum.any?(stored.headers, fn {k, v} -> k == "x-custom-header" and v == "test-value" end)
  end

  test "GET / redirects to /incoming", %{conn: conn} do
    conn = get(conn, "/")
    assert redirected_to(conn) == "/incoming"
  end
end
