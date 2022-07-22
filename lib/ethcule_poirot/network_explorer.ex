defmodule EthculePoirot.NetworkExplorer do
  @moduledoc false
  require Logger
  use GenServer

  alias EthculePoirot.DynamicSupervisor

  @default_api_adapter Application.compile_env(:ethcule_poirot, :default_api_adapter)

  @spec explore(String.t(), pos_integer(), atom() | any()) :: any()
  def explore(eth_address, depth, api_adapter \\ @default_api_adapter) do
    send(__MODULE__, {:start, eth_address, depth, api_adapter})
  end

  @spec start_link(map()) :: any()
  def start_link(initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_info({:start, eth_address, depth, api_adapter}, state) do
    downcased_address = String.downcase(eth_address)
    api_adapter.initial_setup()

    new_state = %{
      eth_address: downcased_address,
      depth: depth,
      visited: MapSet.new(),
      remaining: MapSet.new(),
      api_adapter: api_adapter
    }

    send(__MODULE__, {:visiting, downcased_address, depth})

    {:noreply, Map.merge(state, new_state)}
  end

  @impl true
  def handle_info({:visiting, eth_address, depth}, state) do
    if MapSet.member?(state.visited, eth_address) do
      Logger.info("Already explored #{eth_address}")
      {:noreply, state}
    else
      new_visited = MapSet.put(state.visited, eth_address)
      new_remaining = MapSet.put(state.remaining, eth_address)

      DynamicSupervisor.start_address_explorer(eth_address, depth, state.api_adapter)

      {:noreply, Map.merge(state, %{visited: new_visited, remaining: new_remaining})}
    end
  end

  @impl true
  def handle_info({:visited, eth_address}, state) do
    new_remaining = MapSet.delete(state.remaining, eth_address)

    if MapSet.size(new_remaining) == 0 do
      Neo4j.Client.paint_node(state.eth_address, "Initial")

      Logger.info("Fully explored #{state.eth_address}")
    end

    {:noreply, Map.merge(state, %{remaining: new_remaining})}
  end

  @spec visiting_node(String.t(), pos_integer()) :: any()
  def visiting_node(eth_address, depth) do
    send(__MODULE__, {:visiting, eth_address, depth})
  end

  @spec visited_node(String.t()) :: any()
  def visited_node(eth_address) do
    send(__MODULE__, {:visited, eth_address})
  end
end
