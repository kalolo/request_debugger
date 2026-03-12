defmodule RequestDebuggerWeb.CatchController do
  use RequestDebuggerWeb, :controller
  import Bitwise

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

    remote_ip = conn.remote_ip |> :inet.ntoa() |> to_string()

    client_ip =
      case forwarded_for do
        nil -> remote_ip
        value -> value |> String.split(",") |> List.first() |> String.trim()
      end

    client_ipv4 = resolve_ipv4(client_ip)

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
      remote_ip: remote_ip,
      client_ip: client_ip,
      client_ipv4: client_ipv4,
      forwarded_for: forwarded_for,
      raw_body: raw_body,
      formatted_body: formatted_body,
      timestamp: DateTime.utc_now()
    }

    RequestDebugger.RequestStore.store(request_info)

    json(conn, %{status: "ok"})
  end

  # If already IPv4, return as-is
  defp resolve_ipv4(ip) do
    case :inet.parse_address(String.to_charlist(ip)) do
      {:ok, {_, _, _, _}} ->
        ip

      {:ok, {0, 0, 0, 0, 0, 0xFFFF, hi, lo}} ->
        # IPv4-mapped IPv6 (::ffff:a.b.c.d)
        "#{hi >>> 8}.#{hi &&& 0xFF}.#{lo >>> 8}.#{lo &&& 0xFF}"

      {:ok, ipv6} ->
        # Pure IPv6 — reverse-DNS to hostname, then resolve to IPv4
        resolve_ipv6_to_ipv4(ipv6)

      _ ->
        nil
    end
  end

  defp resolve_ipv6_to_ipv4(ipv6) do
    with {:ok, {:hostent, hostname, _, _, _, _}} <-
           :inet_res.gethostbyaddr(ipv6, timeout: 2000),
         {:ok, {:hostent, _, _, :inet, 4, [ipv4 | _]}} <-
           :inet_res.getbyname(hostname, :a, 2000) do
      ipv4 |> :inet.ntoa() |> to_string()
    else
      _ -> nil
    end
  end
end
