defmodule RequestDebuggerWeb.CacheBodyReader do
  @moduledoc """
  A custom body reader that caches the raw request body in `conn.private[:raw_body]`
  before Plug.Parsers consumes it.
  """

  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = Plug.Conn.put_private(conn, :raw_body, body)
    {:ok, body, conn}
  end
end
