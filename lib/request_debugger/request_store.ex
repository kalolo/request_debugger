defmodule RequestDebugger.RequestStore do
  use Agent

  @topic "requests"

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def store(request_info) do
    id = System.unique_integer([:positive, :monotonic])
    entry = Map.put(request_info, :id, id)
    Agent.update(__MODULE__, fn requests -> [entry | requests] end)
    Phoenix.PubSub.broadcast(RequestDebugger.PubSub, @topic, {:new_request, entry})
    entry
  end

  def list do
    Agent.get(__MODULE__, & &1)
  end

  def clear do
    Agent.update(__MODULE__, fn _ -> [] end)
    Phoenix.PubSub.broadcast(RequestDebugger.PubSub, @topic, :cleared)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(RequestDebugger.PubSub, @topic)
  end
end
