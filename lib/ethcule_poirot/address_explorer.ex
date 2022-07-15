defmodule EthculePoirot.AddressExplorer do
  @moduledoc false
  require Logger
  use GenServer, restart: :transient

  alias EthculePoirot.NetworkExplorer

  def start_link(%{eth_address: eth_address} = initial_state) do
    {:ok, pid} = GenServer.start_link(__MODULE__, initial_state)

    # to not be rate limited by API
    random_sleep = Enum.random(5_000..60_000)
    Logger.info("Querying #{eth_address} | Delay: #{random_sleep / 1000}s")

    if Mix.env() != :test do
      Process.send_after(pid, :start, random_sleep)
    end

    {:ok, pid}
  end

  def init(initial_state) do
    {:ok, initial_state}
  end

  def handle_info(:start, %{depth: 0} = state) do
    address_information = state.api_handler.address_information(state.eth_address)
    update_node_type(address_information.contract, state.eth_address)

    NetworkExplorer.visited_node(state.eth_address)

    {:stop, :normal, state}
  end

  def handle_info(:start, %{depth: depth} = state) do
    state.eth_address
    |> state.api_handler.transactions_for_address()
    |> handle_transactions(depth)

    NetworkExplorer.visited_node(state.eth_address)

    {:stop, :normal, state}
  end

  defp handle_transactions(address_information, depth) do
    update_node_type(address_information.contract, address_information.eth_address)

    Enum.each(address_information.transactions, fn trx ->
      next_address =
        Neo4j.Client.transaction_relation(
          address_information.eth_address,
          trx
        )

      NetworkExplorer.visiting_node(next_address, depth - 1)
    end)
  end

  defp update_node_type(contract_code, eth_address) when not is_nil(contract_code) do
    Neo4j.Client.paint_node(eth_address, "SmartContract")
  end

  defp update_node_type(nil, _eth_address), do: :ok
end
