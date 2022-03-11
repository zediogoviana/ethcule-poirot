defmodule EthculePoirot.NetworkExplorer do
  @moduledoc false

  use GenServer

  alias EthculePoirot.DynamicSupervisor

  def explore(eth_address, depth) do
    send(__MODULE__, {:start, eth_address, depth})
  end

  def start_link(initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_info({:start, eth_address, depth}, state) do
    downcased_address = String.downcase(eth_address)

    new_state = %{
      eth_address: downcased_address,
      depth: depth,
      visited: MapSet.new(),
      remaining: MapSet.new()
    }

    send(__MODULE__, {:visiting, downcased_address, depth})

    {:noreply, Map.merge(state, new_state)}
  end

  def handle_info({:visiting, eth_address, depth}, state) do
    if MapSet.member?(state.visited, eth_address) do
      IO.puts("Already explored #{eth_address}")
      {:noreply, state}
    else
      new_visited = MapSet.put(state.visited, eth_address)
      new_remaining = MapSet.put(state.remaining, eth_address)

      DynamicSupervisor.start_address_explorer(eth_address, depth)

      {:noreply, Map.merge(state, %{visited: new_visited, remaining: new_remaining})}
    end
  end

  def handle_info({:visited, eth_address}, state) do
    new_remaining = MapSet.delete(state.remaining, eth_address)

    if MapSet.size(new_remaining) == 0 do
      Neo4j.Client.paint_node(state.eth_address, "Initial")

      IO.puts("Fully explored #{state.eth_address}")
    end

    {:noreply, Map.merge(state, %{remaining: new_remaining})}
  end

  def visiting_node(eth_address, depth) do
    send(__MODULE__, {:visiting, eth_address, depth})
  end

  def visited_node(eth_address) do
    send(__MODULE__, {:visited, eth_address})
  end
end
