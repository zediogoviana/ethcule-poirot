defmodule Adapters.Api.Blockscout do
  require Logger

  @behaviour Behaviours.Api

  @module_config Application.compile_env(:ethcule_poirot, __MODULE__)

  def initial_setup() do
    Neuron.Config.set(url: Keyword.get(@module_config, :api_url))

    Neuron.Config.set(
      connection_opts: [
        recv_timeout: Keyword.get(@module_config, :api_timeout)
      ]
    )

    :ok
  end

  def address_information(eth_address) do
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

  def transactions_for_address(eth_address) do
    Neuron.query(
      """
        query($eth_address: AddressHash!) {
          address(hash: $eth_address) {
            contractCode
            transactions(first: 22) {
              edges {
                node {
                  hash
                  toAddressHash
                  fromAddressHash
                  value
                  status
                }
              }
              pageInfo {
                hasNextPage
              }
            }
          }
        }
      """,
      %{eth_address: eth_address}
    )
    |> parse_transactions(eth_address)
  end

  def wei_to_eth(value \\ 0) do
    value
    |> Decimal.div(10 ** 18)
    |> Decimal.to_string(:normal)
  end

  defp final_node_type({:ok, %Neuron.Response{body: body}}, _eth_address) do
    contract_code = body["data"]["address"]["contractCode"]
    %Address{contract: contract_code}
  end

  defp final_node_type(_request_result, eth_address) do
    Logger.warn("Failed to obtain address type for #{eth_address}")

    %Address{contract: false}
  end

  defp parse_transactions({:ok, %Neuron.Response{body: body}}, eth_address) do
    transactions = body["data"]["address"]["transactions"]["edges"] || []
    contract_code = body["data"]["address"]["contractCode"]

    transactions_struct =
      Enum.map(
        transactions,
        &%Transaction{
          hash: &1["node"]["hash"],
          to_address: &1["node"]["toAddressHash"],
          from_address: &1["node"]["fromAddressHash"],
          value: wei_to_eth(&1["node"]["value"]),
          status: &1["node"]["status"]
        }
      )

    %Address{
      eth_address: eth_address,
      contract: contract_code,
      transactions: transactions_struct
    }
  end

  defp parse_transactions(_request_result, eth_address) do
    Logger.warn("Failed ETH transactions for #{eth_address}")

    %Address{
      eth_address: eth_address,
      contract: false,
      transactions: []
    }
  end
end
