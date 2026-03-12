defmodule RequestDebuggerWeb.IncomingLive do
  use RequestDebuggerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: RequestDebugger.RequestStore.subscribe()

    requests = RequestDebugger.RequestStore.list()

    {:ok,
     assign(socket,
       requests: requests,
       expanded: MapSet.new(),
       page_title: "Incoming Requests"
     )}
  end

  @impl true
  def handle_info({:new_request, entry}, socket) do
    {:noreply, update(socket, :requests, fn requests -> [entry | requests] end)}
  end

  def handle_info(:cleared, socket) do
    {:noreply, assign(socket, requests: [], expanded: MapSet.new())}
  end

  @impl true
  def handle_event("toggle", %{"id" => id}, socket) do
    id = String.to_integer(id)

    expanded =
      if MapSet.member?(socket.assigns.expanded, id) do
        MapSet.delete(socket.assigns.expanded, id)
      else
        MapSet.put(socket.assigns.expanded, id)
      end

    {:noreply, assign(socket, :expanded, expanded)}
  end

  def handle_event("clear", _, socket) do
    RequestDebugger.RequestStore.clear()
    {:noreply, assign(socket, requests: [], expanded: MapSet.new())}
  end

  defp method_color("GET"), do: "badge-success"
  defp method_color("POST"), do: "badge-info"
  defp method_color("PUT"), do: "badge-warning"
  defp method_color("PATCH"), do: "badge-warning"
  defp method_color("DELETE"), do: "badge-error"
  defp method_color("HEAD"), do: "badge-neutral"
  defp method_color("OPTIONS"), do: "badge-neutral"
  defp method_color(_), do: "badge-primary"

  defp port_display(%{scheme: "http", port: 80}), do: ""
  defp port_display(%{scheme: "https", port: 443}), do: ""
  defp port_display(%{port: port}), do: ":#{port}"

  defp expanded?(expanded, id), do: MapSet.member?(expanded, id)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold">Incoming Requests</h1>
        <div class="flex items-center gap-3">
          <span class="badge badge-lg badge-neutral">{length(@requests)} requests</span>
          <button
            :if={@requests != []}
            phx-click="clear"
            class="btn btn-sm btn-error btn-outline"
            data-confirm="Clear all captured requests?"
          >
            Clear All
          </button>
        </div>
      </div>

      <div :if={@requests == []} class="card bg-base-200 border border-base-300">
        <div class="card-body items-center text-center py-16">
          <.icon name="hero-inbox" class="size-12 opacity-30" />
          <p class="text-lg opacity-50 mt-2">No requests captured yet</p>
          <p class="text-sm opacity-40">
            Send requests to <code class="bg-base-300 px-2 py-1 rounded">/catch/*</code> to see them here
          </p>
        </div>
      </div>

      <div :for={req <- @requests} class="card bg-base-100 border border-base-300">
        <%!-- Clickable header row --%>
        <div
          class="card-body p-4 cursor-pointer hover:bg-base-200 transition-colors"
          phx-click="toggle"
          phx-value-id={req.id}
        >
          <div class="flex items-center gap-3 flex-wrap">
            <span class={["badge font-bold text-white", method_color(req.method)]}>
              {req.method}
            </span>
            <code class="text-sm break-all flex-1">{req.request_path}</code>
            <span class="text-xs opacity-50 whitespace-nowrap">
              {Calendar.strftime(req.timestamp, "%H:%M:%S")}
            </span>
            <.icon
              name={if expanded?(@expanded, req.id), do: "hero-chevron-up", else: "hero-chevron-down"}
              class="size-4 opacity-50"
            />
          </div>
        </div>

        <%!-- Expandable detail --%>
        <div :if={expanded?(@expanded, req.id)} class="border-t border-base-300 p-4 space-y-4">
          <%!-- Full URL --%>
          <div class="bg-base-200 rounded-lg p-3">
            <code class="text-sm break-all">
              {req.scheme}://{req.host}{port_display(req)}{req.request_path}
            </code>
          </div>

          <%!-- Client Info --%>
          <div>
            <h3 class="text-sm font-semibold uppercase tracking-wide opacity-70 mb-2">Client Info</h3>
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-2 text-sm">
              <div>
                <span class="opacity-60">IP:</span> <code>{req.remote_ip}</code>
              </div>
              <div :if={req.forwarded_for}>
                <span class="opacity-60">X-Forwarded-For:</span> <code>{req.forwarded_for}</code>
              </div>
              <div>
                <span class="opacity-60">Scheme:</span> <code>{req.scheme}</code>
              </div>
            </div>
          </div>

          <%!-- Headers --%>
          <div>
            <h3 class="text-sm font-semibold uppercase tracking-wide opacity-70 mb-2">
              Headers <span class="badge badge-sm badge-neutral">{length(req.headers)}</span>
            </h3>
            <div class="overflow-x-auto">
              <table class="table table-sm table-zebra">
                <thead>
                  <tr>
                    <th class="w-1/3">Name</th>
                    <th>Value</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={{name, value} <- req.headers}>
                    <td class="font-semibold text-primary align-top whitespace-nowrap">{name}</td>
                    <td><code class="break-all text-sm">{value}</code></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <%!-- Query Parameters --%>
          <div :if={req.query_params != %{}}>
            <h3 class="text-sm font-semibold uppercase tracking-wide opacity-70 mb-2">
              Query Parameters
              <span class="badge badge-sm badge-neutral">{map_size(req.query_params)}</span>
            </h3>
            <div class="overflow-x-auto">
              <table class="table table-sm table-zebra">
                <thead>
                  <tr>
                    <th class="w-1/3">Key</th>
                    <th>Value</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={{key, value} <- req.query_params}>
                    <td class="font-semibold text-secondary align-top">{key}</td>
                    <td><code class="break-all text-sm">{inspect(value)}</code></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <%!-- Parsed Body Parameters --%>
          <div :if={req.body_params != %{} and not match?(%Plug.Conn.Unfetched{}, req.body_params)}>
            <h3 class="text-sm font-semibold uppercase tracking-wide opacity-70 mb-2">
              Parsed Body Parameters
            </h3>
            <div class="overflow-x-auto">
              <table class="table table-sm table-zebra">
                <thead>
                  <tr>
                    <th class="w-1/3">Key</th>
                    <th>Value</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={{key, value} <- req.body_params}>
                    <td class="font-semibold text-accent align-top">{key}</td>
                    <td><code class="break-all text-sm">{inspect(value, pretty: true)}</code></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <%!-- Raw Body --%>
          <div :if={req.raw_body != ""}>
            <h3 class="text-sm font-semibold uppercase tracking-wide opacity-70 mb-2">
              Raw Body <span class="badge badge-sm badge-neutral">{byte_size(req.raw_body)} bytes</span>
            </h3>
            <pre class="bg-base-200 rounded-lg p-4 overflow-x-auto text-sm"><code>{req.formatted_body}</code></pre>
          </div>

          <%!-- All Merged Params --%>
          <div :if={req.params != %{}}>
            <h3 class="text-sm font-semibold uppercase tracking-wide opacity-70 mb-2">
              All Merged Params
            </h3>
            <pre class="bg-base-200 rounded-lg p-4 overflow-x-auto text-sm"><code>{inspect(req.params, pretty: true, width: 80)}</code></pre>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
