defmodule EthculePoirot.NetworkExplorer do
  @moduledoc false
  require Logger
  use GenServer

  alias EthculePoirot.DynamicSupervisor

  @default_api_adapter Application.compile_env(:ethcule_poirot, :default_api_adapter)
  @pool_size Application.compile_env(:ethcule_poirot, :pool_size)

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
      known: MapSet.new(),
      exploring: MapSet.new(),
      remaining: [],
      api_adapter: api_adapter,
      processes_count: 0
    }

    send(__MODULE__, {:add_to_queue, downcased_address, depth})

    {:noreply, Map.merge(state, new_state)}
  end

  @impl true
  def handle_info({:add_to_queue, eth_address, depth}, state) do
    if MapSet.member?(state.known, eth_address) do
      Logger.info("Already explored #{eth_address}")
      {:noreply, state}
    else
      new_known = MapSet.put(state.known, eth_address)

      {processes_count, new_remaining, new_exploring} =
        add_to_queue(
          eth_address,
          depth,
          state
        )

      {:noreply,
       Map.merge(state, %{
         known: new_known,
         exploring: new_exploring,
         remaining: new_remaining,
         processes_count: processes_count
       })}
    end
  end

  @impl true
  def handle_info({:remove_from_queue, eth_address}, state) do
    new_exploring = MapSet.delete(state.exploring, eth_address)
    exploring_size = MapSet.size(new_exploring)
    remaining_size = length(state.remaining)

    {processes_count, new_remaining, new_exploring} =
      remove_from_queue(
        exploring_size,
        remaining_size,
        %{state | exploring: new_exploring}
      )

    {:noreply,
     Map.merge(state, %{
       remaining: new_remaining,
       exploring: new_exploring,
       processes_count: processes_count
     })}
  end

  @spec visit_node(String.t(), pos_integer()) :: any()
  def visit_node(eth_address, depth) do
    send(__MODULE__, {:add_to_queue, eth_address, depth})
  end

  @spec node_visited(String.t()) :: any()
  def node_visited(eth_address) do
    send(__MODULE__, {:remove_from_queue, eth_address})
  end

  @spec add_to_queue(String.t(), pos_integer(), map()) :: {pos_integer(), list(), MapSet.t()}
  defp add_to_queue(eth_address, depth, %{processes_count: processes} = state)
       when processes < @pool_size do
    DynamicSupervisor.start_address_explorer(eth_address, depth, state.api_adapter)

    new_exploring = MapSet.put(state.exploring, eth_address)
    {state.processes_count + 1, state.remaining, new_exploring}
  end

  defp add_to_queue(eth_address, depth, state) do
    new_remaining = [{eth_address, depth} | state.remaining]

    {state.processes_count, new_remaining, state.exploring}
  end

  @spec remove_from_queue(pos_integer(), pos_integer(), map()) ::
          {pos_integer(), list(), MapSet.t()}
  defp remove_from_queue(0, 0, state) do
    Neo4j.Client.set_node_label(state.eth_address, "Initial")

    Logger.info("Fully explored #{state.eth_address}")
    {0, state.remaining, state.exploring}
  end

  defp remove_from_queue(_exploring_size, remaining_size, state) when remaining_size > 0 do
    [{next_address, next_depth} | new_remaining] = state.remaining
    new_exploring = MapSet.put(state.exploring, next_address)

    DynamicSupervisor.start_address_explorer(next_address, next_depth, state.api_adapter)
    {state.processes_count, new_remaining, new_exploring}
  end

  defp remove_from_queue(_exploring_size, _remaining_size, state) do
    {state.processes_count - 1, state.remaining, state.exploring}
  end
end
