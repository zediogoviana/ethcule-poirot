defmodule Adapters.Api.DissrupTheGraph do
  @moduledoc false
  require Logger

  @behaviour Behaviours.Api

  @module_config Application.compile_env(:ethcule_poirot, __MODULE__)

  @impl true
  def initial_setup do
    Neuron.Config.set(url: Keyword.get(@module_config, :api_url))

    Neuron.Config.set(
      connection_opts: [
        recv_timeout: Keyword.get(@module_config, :api_timeout)
      ]
    )

    :ok
  end

  @impl true
  def address_information(_eth_address) do
    %Address{contract: false}
  end

  @impl true
  def transactions_for_address(eth_address) do
    Neuron.query(
      """
        query($eth_address: Bytes!) {
          account(id: $eth_address) {
            sales(first: 1000) {
              price
              transaction {
                id
              }
              asset {
                assetId
                contractAddress
                contractType
                URI
              }
              buyer {
                address
              }
            }
            buys(first: 1000) {
              price
              seller {
                address
              }
              transaction {
                id
              }
              asset {
                assetId
                contractAddress
                contractType
                URI
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

  @spec parse_transactions({:ok, any()}, String.t()) :: Address.t()
  defp parse_transactions({:ok, %Neuron.Response{body: body}}, eth_address) do
    sales = body["data"]["account"]["sales"] || []
    buys = body["data"]["account"]["buys"] || []

    sales_transactions_struct =
      Enum.map(
        sales,
        &%Transaction{
          hash: &1["transaction"]["id"],
          to_address: &1["buyer"]["address"],
          from_address: eth_address,
          value: wei_to_eth(&1["price"]),
          status: "OK"
        }
      )

    buys_transactions_struct =
      Enum.map(
        buys,
        &%Transaction{
          hash: &1["transaction"]["id"],
          to_address: eth_address,
          from_address: &1["seller"]["address"],
          value: wei_to_eth(&1["price"]),
          status: "OK"
        }
      )

    %Address{
      eth_address: eth_address,
      contract: false,
      transactions: buys_transactions_struct ++ sales_transactions_struct
    }
  end

  @spec parse_transactions({:error, any()}, String.t()) :: Address.t()
  defp parse_transactions(_request_result, eth_address) do
    Logger.warn("Failed ETH transactions for #{eth_address}")

    %Address{
      eth_address: eth_address,
      contract: false,
      transactions: []
    }
  end
end
