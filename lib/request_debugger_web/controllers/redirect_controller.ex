defmodule RequestDebuggerWeb.RedirectController do
  use RequestDebuggerWeb, :controller

  def to_incoming(conn, _params) do
    redirect(conn, to: ~p"/incoming")
  end
end
