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

  def handle_info(:start, state) do
    explore_address(state.eth_address, state.depth)
    NetworkExplorer.visited_node(state.eth_address)

    {:stop, :normal, state}
  end

  defp explore_address(eth_address, 0) do
    Neuron.query(
      """
        query($eth_address: AddressHash!) {
          address(hash: $eth_address) {
            contractCode
          }
        }
      """,
      %{eth_address: eth_address}
    )
    |> final_node_type(eth_address)
  end

  defp explore_address(eth_address, depth) do
    eth_address
    |> request_address_transactions()
    |> process_transactions(eth_address, depth)
  end

  defp request_address_transactions(eth_address) do
    Neuron.query(
      """
        query($eth_address: AddressHash!) {
          address(hash: $eth_address) {
            contractCode
            transactions(last: 23, count: 23) {
              edges {
                node {
                  hash
                  toAddressHash
                  fromAddressHash
                  value
                  status
                }
              }
            }
          }
        }
      """,
      %{eth_address: eth_address}
    )
  end

  defp final_node_type({:ok, %Neuron.Response{body: body}}, eth_address) do
    contract_code = body["data"]["address"]["contractCode"]
    update_node_type(contract_code, eth_address)
  end

  defp final_node_type(_request_result, eth_address) do
    Logger.info("Failed to obtain address type for #{eth_address}")
    nil
  end

  defp process_transactions({:ok, %Neuron.Response{body: body}}, eth_address, depth) do
    transactions = body["data"]["address"]["transactions"]["edges"] || []
    contract_code = body["data"]["address"]["contractCode"]
    update_node_type(contract_code, eth_address)

    Enum.each(transactions, fn trx ->
      next_address = Neo4j.Client.transaction_relation(eth_address, trx)

      NetworkExplorer.visiting_node(next_address, depth - 1)
    end)
  end

  defp process_transactions(_request_result, eth_address, _depth) do
    Logger.info("Failed ETH transactions for #{eth_address}")
    nil
  end

  defp update_node_type(contract_code, eth_address) when not is_nil(contract_code) do
    Neo4j.Client.paint_node(eth_address, "SmartContract")
  end

  defp update_node_type(nil, _eth_address), do: nil
end
