defmodule EthculePoirot.AddressExplorer do
  @moduledoc false
  require Logger
  use GenServer, restart: :transient

  alias EthculePoirot.NetworkExplorer

  @spec start_link(%{
          eth_address: String.t(),
          depth: pos_integer(),
          api_handler: atom()
        }) ::
          {:ok, pid()}
  def start_link(%{eth_address: eth_address} = initial_state) do
    {:ok, pid} = GenServer.start_link(__MODULE__, initial_state)

    Logger.info("Querying #{eth_address}")
    send(pid, :start)

    {:ok, pid}
  end

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_info(:start, %{depth: 0} = state) do
    address_information = state.api_handler.address_information(state.eth_address)
    update_node_type(address_information.contract, state.eth_address)

    NetworkExplorer.node_visited(state.eth_address)

    {:stop, :normal, state}
  end

  @impl true
  def handle_info(:start, %{depth: depth} = state) do
    state.eth_address
    |> state.api_handler.transactions_for_address()
    |> handle_transactions(depth)

    NetworkExplorer.node_visited(state.eth_address)

    {:stop, :normal, state}
  end

  @spec handle_transactions(Address.t(), pos_integer()) :: any()
  defp handle_transactions(address_information, depth) do
    update_node_type(address_information.contract, address_information.eth_address)

    Enum.each(address_information.transactions, fn trx ->
      next_address =
        Neo4j.Client.transaction_relation(
          address_information.eth_address,
          trx
        )

      NetworkExplorer.visit_node(next_address, depth - 1)
    end)
  end

  @spec update_node_type(true, String.t()) :: any()
  defp update_node_type(contract_code, eth_address) when contract_code do
    Neo4j.Client.paint_node(eth_address, "SmartContract")
  end

  @spec update_node_type(nil | false, String.t()) :: any()
  defp update_node_type(_nil, _eth_address), do: :ok
end
