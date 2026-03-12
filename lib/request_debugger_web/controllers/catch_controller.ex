defmodule RequestDebuggerWeb.CatchController do
  use RequestDebuggerWeb, :controller

  def capture(conn, params) do
    raw_body = conn.private[:raw_body] || ""

    formatted_body =
      case Jason.decode(raw_body) do
        {:ok, decoded} -> Jason.encode!(decoded, pretty: true)
        _ -> raw_body
      end

    forwarded_for =
      Enum.find_value(conn.req_headers, fn
        {"x-forwarded-for", value} -> value
        _ -> nil
      end)

    request_info = %{
      method: conn.method,
      scheme: to_string(conn.scheme),
      host: conn.host,
      port: conn.port,
      request_path: conn.request_path,
      query_string: conn.query_string,
      query_params: conn.query_params,
      body_params: conn.body_params,
      params: Map.drop(params, ["path"]),
      headers: conn.req_headers,
      remote_ip: conn.remote_ip |> :inet.ntoa() |> to_string(),
      forwarded_for: forwarded_for,
      raw_body: raw_body,
      formatted_body: formatted_body,
      timestamp: DateTime.utc_now()
    }

    RequestDebugger.RequestStore.store(request_info)

    json(conn, %{status: "ok"})
  end
end
